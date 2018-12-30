FROM baseimage:0.11 AS build
ARG OPENLDAP_URL_MD5=http://www.openldap.org/software/download/OpenLDAP/openldap-release/openldap-2.4.47.md5
ARG OPENLDAP_URL_TGZ=http://www.openldap.org/software/download/OpenLDAP/openldap-release/openldap-2.4.47.tgz

# Install OpenLDAP dependencies 
RUN set -x && \
    install_clean \
        g++ \
        groff \
        groff-base \
        libltdl-dev \
        libsasl2-dev \
        libssl-dev \
        libtool \
        make

# Download and extract OpenLDAP to /bd_build, which was created in baseimage
WORKDIR /bd_build
RUN set -x && \
    curl --output openldap.tgz $OPENLDAP_URL_TGZ && \
    curl --output openldap.md5 $OPENLDAP_URL_MD5 && \
    echo "$(grep -oe '[a-f0-9]\{32\}' openldap.md5)  openldap.tgz" > openldap.md5 && \
    md5sum --check openldap.md5 && \
    tar -xzvf openldap.tgz && \
    rm openldap.tgz openldap.md5 && \
    mv openldap* openldap

# Configure OpenLDAP, build and install
WORKDIR /bd_build/openldap
RUN set -x && \
    ./configure --disable-dependency-tracking \ 
        --disable-static \
        --enable-bdb=no \
        --enable-dynamic \
        --enable-fast-install=yes \
        --enable-hdb=no \
        --enable-ipv6=yes \
        --enable-syslog=yes \
        --libexecdir=/usr/bin \
        --localstatedir=/var \
        --prefix=/usr \
        --sysconfdir=/etc \
        --with-cyrus-sasl=yes \
        --with-threads=yes \
        --with-tls=openssl && \
    make depend && \
    make && \
    make install

# Multi-State: Move build OpenLDAP binaries to a fresh image
FROM baseimage:0.11

COPY --from=build /usr /usr
COPY --from=build /etc/openldap /etc/openldap
COPY openldap /etc/service/openldap

# Do some cleanup (remove unecessary man pages), create an ldap user, set proper permissions and set the runit slapd service to be executable
RUN set -x && \
    find /usr/share/man -regextype sed -regex ".*/\(ldap.*\|slap.*\)" | xargs rm -v && \
    groupadd -r ldap && \
    useradd -r -g ldap -s /usr/sbin/nologin -d /usr/local/etc/openldap -c "OpenLDAP server" ldap && \
    chown -vR root:ldap /etc/openldap && \
    chmod -vR 650 /etc/openldap && \
    chmod -v +x /etc/service/openldap/run

ENTRYPOINT ["/sbin/my_init"]
