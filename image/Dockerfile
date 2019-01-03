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
# md5sum requires a specific format in the md5 file we give it
    echo "$(grep -oe '[a-f0-9]\{32\}' openldap.md5)  openldap.tgz" > openldap.md5 && \
    md5sum --check openldap.md5 && \
    tar -xzvf openldap.tgz && \
    rm openldap.tgz openldap.md5 && \
# ensure that whatever folder we extract from the archive is named openldap
    mv openldap* openldap

# Configure OpenLDAP, build and install
# Use mdb backend, with ipv6, tls, syslog and sasl support
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

# Nothing in /var that we need to copy over at this point, just copy over /usr and /etc/openldap
COPY --from=build /usr /usr
COPY --from=build /etc/openldap /etc/openldap
# Copy the slapd runit service file from the build context
COPY service/openldap /etc/service/openldap
# Copy over configuration files from build context- any files in context will overwrite defaults
COPY openldap /etc/openldap

# Final cleanups
RUN set -x && \
# Delete all man pages, as man isn't installed in this image anyway (saves a lot of space)
    find /usr/share/man -regextype sed -regex ".*/\(ldap.*\|slap.*\)" | xargs rm -v && \
# Create ldap user and group which slapd will run as
    groupadd -r ldap && \
    useradd -r -g ldap -s /usr/sbin/nologin -d /usr/local/etc/openldap -c "OpenLDAP server" ldap && \
    chown -vR root:ldap /etc/openldap && \
# Change permissions on configuration and service files
    chmod -vR 650 /etc/openldap && \
    chmod -v +x /etc/service/openldap/run

ENTRYPOINT ["/sbin/my_init"]
