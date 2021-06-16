#!/bin/sh
# setup.sh --- set up openbsd server

### POSIX strict-ish mode, beware eager pipelines!:
set -eu
IFS=$'\n\t'

### Env:
GEMINI_USER="${GEMINI_USER-gemboi}"
NEWHOSTNAME="${NEWHOSTNAME-cadadr.space}"

### Prep:
echo '#!/bin/sh' > /etc/daily.local
mkdir -p /var/gemini
mkdir -p "/var/www/htdocs/$NEWHOSTNAME"

chmod 750 /etc/daily.local

pkg_add git

### Gemini:
# add gemini user
id gemboi || useradd -v -s /sbin/nologin -c 'gemini user' -d /var/gemini gemboi

# inetd.conf
echo 11965 stream tcp nowait gemboi /usr/local/bin/vger vger > /etc/inetd.conf

# relayd.conf
cat <<EOF > /etc/relayd.conf
log connection
tcp protocol "gemini" {
    tls keypair $NEWHOSTNAME
}

relay "gemini" {
    listen on 0.0.0.0 port 1965 tls
    protocol "gemini"
    forward to 127.0.0.1 port 11965
}
EOF

# create self-signed SSL cert
if [ ! -f "/etc/ssl/private/$NEWHOSTNAME.key" ]; then
    openssl genrsa -out "/etc/ssl/private/$NEWHOSTNAME.key" 4096
    openssl req -new -key "/etc/ssl/private/$NEWHOSTNAME.key" \
            -subj "/C=TR/ST=Ist/L=Ist/O=NA/CN=$NEWHOSTNAME"   \
            -out "/etc/ssl/private/$NEWHOSTNAME.csr"
    openssl x509 -sha256 -req -days 365 \
            -in "/etc/ssl/private/$NEWHOSTNAME.csr" \
            -signkey "/etc/ssl/private/$NEWHOSTNAME.key" \
            -out "/etc/ssl/$NEWHOSTNAME.crt"
fi

# test content for gemini server
[ -f /var/gemini/index.gmi ] \
    || echo "# Hello world" >> /var/gemini/index.gmi

# install vger
which vger || {
    # TODO(2021-03-04): change to private clone
    git clone https://github.com/cadadr/tildegit-solene-vger /root/vger;
    ( cd /root/vger ; make install );
}


### HTTP:
# based on https://www.openbsdhandbook.com/services/webserver/ssl/

# letsencrypt setup
cat > /etc/acme-client.conf <<EOF
authority letsencrypt {
    api url "https://acme-v02.api.letsencrypt.org/directory"
    account key "/etc/acme/letsencrypt-privkey.pem"
}

authority letsencrypt-staging {
    api url "https://acme-staging-v02.api.letsencrypt.org/directory"
    account key "/etc/acme/letsencrypt-staging-privkey.pem"
}

domain $NEWHOSTNAME {
    domain key "/etc/ssl/private/$NEWHOSTNAME-le.key"
    domain certificate "/etc/ssl/$NEWHOSTNAME-le.crt"
    domain full chain certificate "/etc/ssl/$NEWHOSTNAME-le.fullchain.pem"
    sign with letsencrypt
}
EOF

# httpd setup
cat > /etc/httpd.conf <<EOF
server "$NEWHOSTNAME" {
    listen on * tls port 443
    root "/htdocs/$NEWHOSTNAME"
    tls {
        certificate "/etc/ssl/$NEWHOSTNAME-le.fullchain.pem"
        key "/etc/ssl/private/$NEWHOSTNAME-le.key"
    }

    # acme challenges, acme-client deletes stuff here
    # after its operation.
    location "/.well-known/acme-challenge/*" {
        root "/acme"
        request strip 2
    }
}

include "/tmp/httpd.conf.pre-le"
EOF

# config for initial run of acme-client
cat > /tmp/httpd.conf.pre-le <<EOF
# config for initial run of acme-client

server "$NEWHOSTNAME" {
    listen on * port 80
    location "/.well-known/acme-challenge/*" {
        root "/acme"
        request strip 2
    }
}
EOF

# initial
httpd -n && rcctl enable httpd && rcctl start httpd \
    && rcctl restart httpd      # make sure configs are up to date
acme-client -v "$NEWHOSTNAME"

# Now, remove httpd.conf.pre-le, and configure for proper redirection
sed -i 's/include "\/tmp\/httpd\.conf\.pre-le"//'  /etc/httpd.conf
cat >> /etc/httpd.conf <<EOF
# redirect http to https
server "cadadr.space" {
    listen on * port 80
    block return 301 "https://cadadr.space$REQUEST_URI"
}
EOF
rcctl restart httpd

# certificate renewal, check daily, updates only when necessary
echo 'acme-client cadadr.space && rcctl reload httpd' >> /etc/daily.local

# test content
homepage="/var/www/htdocs/$NEWHOSTNAME/index.html"
[ -f "$homepage" ] || echo "<h1>Hello, world!</h1>" > "$homepage"

### Services:
rcctl enable relayd inetd
rcctl start relayd inetd
rcctl restart relayd inetd
rcctl disable sndiod

### Post:
chown -R gemboi:gemboi /var/gemini

echo "setup done, consider rebooting"
