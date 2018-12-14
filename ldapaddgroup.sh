#!/bin/bash
set -u

CONFIG_FILE=$HOME/.ntuhpcldap.conf
if [ ! -f $CONFIG_FILE ]; then
	echo "Config file ${CONFIG_FILE} doesn't exist!"
	exit 1
fi
. $CONFIG_FILE

if [ "$#" -ne 1 ]; then
	echo 'Usage: ldapaddgroup.sh <groupname>'
	exit 1
fi
GROUP=$1

echo -n Enter LDAP admin password:
read -s LDAP_PASSWD
echo

LIST_OF_GROUPS=`ldapsearch -x -D "${LDAP_BIND_DN}" -w ${LDAP_PASSWD} -b "dc=ntuhpc,dc=org" -H "${LDAP_SERVER}" -s sub "objectClass=posixGroup"`
if echo "${LIST_OF_GROUPS}" | grep -q ${GROUP}; then
	echo "Group ${GROUP} already exists!"
	exit 1
fi

LARGEST_GID=`echo "${LIST_OF_GROUPS}" | grep gidNumber | cut -d" " -f2 | sort | tail -n 1`
GIDNUMBER=`expr ${LARGEST_GID} + 1`

ldapadd -x -D "${LDAP_BIND_DN}" -w ${LDAP_PASSWD} -H "${LDAP_SERVER}" > /dev/null << EOF && echo Group ${GROUP} created
dn: cn=${GROUP},ou=posixgroups,dc=ntuhpc,dc=org
objectClass: top
objectClass: posixGroup
cn: ${GROUP}
gidNumber: ${GIDNUMBER}
EOF
