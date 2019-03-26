#!/bin/sh

# Fail the script if any of these commands fail ("-e" option)
set -x -e

# Set proper permissions on slapd config file
chown -v ldap:ldap "${SLAPD_CONFIG_LDIF}"
chmod -v 640 "${SLAPD_CONFIG_LDIF}"

# Set proper permissions on all directories used for databases specified in the config
grep "olcDbDirectory:" "${SLAPD_CONFIG_LDIF}" | awk -F ":" '{print $2}' | while IFS= read -r db; do
    if [ -n "$db" ]; then
        mkdir -p $db
        chown -vR ldap:ldap $db
        chmod -vR 777 $db
    fi
done

# Remove existing configuration, if needed
if [ -d "/usr/local/etc/openldap/slapd.d" ]; then
    rm -rfv /usr/local/etc/openldap/slapd.d
fi

# Create empty config directory
mkdir /usr/local/etc/openldap/slapd.d
chown -v ldap:ldap /usr/local/etc/openldap/slapd.d

# Create slapd configuration from the slapd config ldif, using slapdadd utility
/sbin/setuser ldap /usr/local/sbin/slapadd -n0 -v -F /usr/local/etc/openldap/slapd.d -l "${SLAPD_CONFIG_LDIF}"

# Set proper permissions from slapd.pid and slapd.args files if needed, as since we are running
# slapd as a non-root user they need to be created beforehand
# Look for pid and args file definitions in the given slapd ldif config, setting defaults if not given
pidFileLdif="$(grep "olcPidFile:" "${SLAPD_CONFIG_LDIF}" | awk -F ":" '{print $2}')"
pidFile=${pidFileLdif:="/var/run/slapd.pid"}
argsFileLdif="$(grep "olcArgsFile:" "${SLAPD_CONFIG_LDIF}" | awk -F ":" '{print $2}')"
argsFile=${argsFileLdif:="/var/slapd.args"}

# Create the pid file and all parent directories
for f in $pidFile $argsFile; do
    if [ ! -e "$f" ]; then
        mkdir -p $f
        rm -r $f
        touch $f
    fi
done

# Give ownership of the pid file to ldap:ldap, permissions set at 640
chown -v ldap:ldap $pidFile $argsFile
chmod -v 640 $pidFile $argsFile

# Test configuration to make sure we are all good to go
/sbin/setuser ldap /usr/local/sbin/slaptest -n0 -v -F /usr/local/etc/openldap/slapd.d
