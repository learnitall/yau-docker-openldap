#!/bin/sh
/etc/openldap/openldap-docker/load_secrets.py $OPENLDAP_CONF_FILE --secrets-dir $OPENLDAP_SECRETS_DIR | ldapmodify -Y EXTERNAL -h ldapi:///
