FROM centos:7

ARG OPENLDAP_URL_MD5=https://www.openldap.org/software/download/OpenLDAP/openldap-release/openldap-2.4.47.md5
ARG OPENLDAP_URL_TGZ=https://www.openldap.org/software/download/OpenLDAP/openldap-release/openldap-2.4.47.tgz

# Install OpenLDAP dependencies need for build
RUN set -ex && \
    yum -y install \
      g++ \
      groff \
      groff-base \
      libltdl-dev \
      libsasl2-dev \
      libssl-dev \
      libtool \
      make && \
    yum -y clean all

# Download and extract OpenLDAP to /build
RUN set -ex && \
    mkdir /build && \
    cd /build && \
    curl -v --output openldap.tgz $OPENLDAP_URL_TGZ && \
    curl -v --output openldap.md5 $OPENLDAP_URL_MD5 && \
# md5sum requires a specific format in the md5 file we give it
    echo "$(grep -oe '[a-f0-9]\{32\}' openldap.md5) openldap.tgz" > openldap.md5 && \
    md5sum --check openldap.md5 && \
    tar -xzvf openldap.tgz && \
    rm -v openldap.tgz openldap.md5 && \
# Ensure that whatever folder we extract from the archive is still named openldap
    mv openldap* openldap

# Configure OpenLDAP, build (with a preset list of options) and install
WORKDIR /build/openldap
RUN set -ex && \
    ./configure --disable-dependency-tracking \
        --disable-static \
        --enable-bdb=no \
        --enable-dynamic \
        --enable-fast-install=yes \
        --enable-hdb=no \
        --enable-ipv6=yes \
        --enable-syslog=yes \
        --with-cyrus-sasl=yes \
        --with-threads=yes \
        --with-tls=openssl && \
    make depend && \
    make && \
    make install

# Final cleanups
RUN set -ex && \
    rm -rv /build && \
# Create ldap user and group
    groupadd -r ldap && \
    useradd -r -g ldap -s /usr/sbin/nologin -d /usrs/local/etc/opeenldap -c "OpenLDAP server" ldap && \
# Change permissions on figuration files
    chown -vR root:ldap /usr/local/etc/openldap && \
    chmod -vR 650 /usr/local/etc/openldap


# Add path to dynamically linked ldap libraries
ENV LD_LIBRARY_PATH="$LD_LIBRARY_PATH:/usr/local/lib"
# Location of slapd ldif config file to create cn=config database on entry
ENV SLAPD_CONFIG_LDIF="/usr/local/etc/openldap/slapd.ldif"

# Volume where data is stored
VOLUME /usr/local/var/openldap-data

# Entrypoint
COPY docker-entrypoint.sh /usr/local/bin
ENTRYPOINT ["docker-entrypoint.sh"]

# Ports for slapd on ldap:/// and ldaps:///
EXPOSE 389 636
CMD ["slapd"]

