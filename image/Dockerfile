FROM baseimage:0.11 as build

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

# Download and extract OpenLDAP to /bd_build
WORKDIR /bd_build
RUN set -x && \
    wget -v --output-document openldap.tgz $OPENLDAP_URL_TGZ && \
    wget -v --output-document openldap.md5 $OPENLDAP_URL_MD5 && \
# md5sum requires a specific format in the md5 file we give it
    echo "$(grep -oe '[a-f0-9]\{32\}' openldap.md5)  openldap.tgz" > openldap.md5 && \
    md5sum --check openldap.md5 && \
    tar -xzvf openldap.tgz && \
    rm openldap.tgz openldap.md5 && \
# ensure that whatever folder we extract from the archive is named openldap
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
        --with-cyrus-sasl=yes \
        --with-threads=yes \
        --with-tls=openssl && \
    make depend && \
    make && \
    make install


# Start from a fresh image
FROM baseimage:0.11

# Add path to dynamically linked libraries
ENV LD_LIBRARY_PATH="$LD_LIBRARY_PATH:/usr/local/lib"
# Location of slapd ldif config file to create cn=config database
ENV SLAPD_CONFIG_LDIF=/usr/local/etc/openldap/slapd.ldif

# Copy over built openldap files
COPY --from=build /usr/local /usr/local
# Copy the slapd runit service file from the build context
COPY service/openldap /etc/service/openldap
# Copy the slapd config init service from the build context
COPY my_init.d /etc/my_init.d

# Final cleanups
RUN set -x && \
# Delete all man pages, as man isn't installed in this image anyway (saves some space)
    find /usr/local/share/man -regextype sed -regex ".*/\(ldap.*\|slap.*\)" | xargs rm -v && \
# Remove bd_build directory, as we don't need it anymore
    rm -rv /bd_build && \
# Create ldap user and group which slapd will run as
    groupadd -r ldap && \
    useradd -r -g ldap -s /usr/sbin/nologin -d /usr/local/etc/openldap -c "OpenLDAP server" ldap && \
# Change permssions on configuration files
    chown -vR root:ldap /usr/local/etc/openldap && \
    chmod -vR 650 /usr/local/etc/openldap && \
# Set permissinos on service and init files
    chmod -v +x /etc/service/openldap/run && \
    chmod -vR +x /etc/my_init.d


WORKDIR /usr/local/etc/openldap
ENTRYPOINT ["/sbin/my_init"]

