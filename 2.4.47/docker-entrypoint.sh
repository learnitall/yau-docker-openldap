#!/bin/bash
set -e

# if command starts with an option, then prepend slapd
if [ "${1:0:1}" == "-" ]; then
    set -- slapd "$@"
fi

# skip setup if they want a documented option that stops slapd
# does not included invalid input such as -? or --help
wantHelp=
wantDebug=
for arg; do
    case "$arg" in
        -VV|-VVV)
            wantHelp=1
            break
            ;;
        -d)
            wantDebug=1
            ;;
        '?')
            if [ $wantDebug == 1 ]; then
                wantHelp=1
                break
            fi
            ;;
    esac
done

if [ "$1" == "slapd" -a -z "$wantHelp" -a ! -d "/usr/local/etc/openldap/slapd.d" ]; then

    echo "Configuration directory doesn't exist, performing initial setup"

    # Set proper permissions on slapd config file
    echo "Setting permissions on slapd config file"
    chown -v ldap:ldap "${SLAPD_CONFIG_LDIF}"
    chmod -v 640 "${SLAPD_CONFIG_LDIF}"

    # Set proper permissions on all directories used for databases specific in the config
    echo "Setting permissions on all data directories"
    grep "olcDbDirectory:" "${SLAPD_CONFIG_LDIF}" | awk -F ":" '{print $2}' | while IFS= read -r db; do
        if [ -n "$db" ]; then
            echo "Setting permissions on $db"
            mkdir -p $db
            chown -vR ldap:ldap $db
            chmod -vR 777 $db
        fi
    done

    # Create slapd configuration from the slapd config ldif, using slapdadd utility
    echo "Creating slapd configuration using slapadd"
    mkdir -p /usr/local/etc/openldap/slapd.d
    chown -v ldap:ldap /usr/local/etc/openldap/slapd.d
    gosu ldap /usr/local/sbin/slapadd -n0 -v -F /usr/local/etc/openldap/slapd.d -l "${SLAPD_CONFIG_LDIF}"

    # Set proper permissions on slapd.pid and slapd.args files
    echo "Creating and setting permissions on slapd pid and args files"
    pidFileLdif="$(grep "olcPidFile:" "${SLAPD_CONFIG_LDIF}" | awk -F ":" '{print $2}')"
    pidFile=${pidFileLdif:="/var/run/slapd.pid"}
    argsFileLdif="$(grep "olcArgsFile:" "${SLAPD_CONFIG_LDIF}" | awk -F ":" '{print $2}')"
    argsFile=${argsFileLdif:="/var/slapd.args"}
    for f in $pidFile $argsFile; do
        if [ ! -e "$f" ]; then
            mkdir -p $f
            rm -r $f
            touch $f
        fi
    done
    chown -v ldap:ldap $pidFile $argsFile
    chmod -v 640 $pidFile $argsFile

    # Test configuration
    echo "Testing configuration"
    gosu ldap /usr/local/sbin/slaptest -n0 -v -F /usr/local/etc/openldap/slapd.d

    echo "Initial setup complete. Starting slapd"
fi

exec "$@"

