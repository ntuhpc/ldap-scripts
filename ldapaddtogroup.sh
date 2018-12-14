#!/bin/bash
set -u

CONFIG_FILE=$HOME/.ntuhpcldap.conf
if [ ! -f $CONFIG_FILE ]; then
	echo "Config file ${CONFIG_FILE} doesn't exist!"
	exit 1
fi
. $CONFIG_FILE

if [ "$#" -ne 2 ]; then
	echo "Usage: ldapaddtogroup.sh <username> <group>"
	exit 1
fi

USERNAME=$1
GROUP=$2

echo -n Enter LDAP admin password:
read -s LDAP_PASSWD
echo

# check if user exists
USER_RESULT=`ldapsearch -x -D "${LDAP_BIND_DN}" -w ${LDAP_PASSWD} -b "ou=people,dc=ntuhpc,dc=org" -H "${LDAP_SERVER}" -s sub "cn=${USERNAME}"`
if ! echo "${USER_RESULT}" | grep -q "numEntries"; then
	echo "User ${USERNAME} doesn't exist"
	exit 1
fi

# check if group exists
GROUP_RESULT=`ldapsearch -x -D "${LDAP_BIND_DN}" -w ${LDAP_PASSWD} -b "ou=posixgroups,dc=ntuhpc,dc=org" -H "${LDAP_SERVER}" -s sub "cn=${GROUP}"`
if ! echo "${GROUP_RESULT}" | grep -q "numEntries"; then
	echo "Group ${GROUP} doesn't exist"
	exit 1
fi

# check if user already in group
if echo "${GROUP_RESULT}" | grep -q "${USERNAME}"; then
	echo "User ${USERNAME} already in group ${GROUP}"
	exit 1
fi

ldapmodify -x -D "${LDAP_BIND_DN}" -w ${LDAP_PASSWD} -H "${LDAP_SERVER}" > /dev/null << EOF && echo User ${USERNAME} added to group ${GROUP}
dn: cn=${GROUP},ou=posixgroups,dc=ntuhpc,dc=org
changetype: modify
add: memberUid
memberUid: ${USERNAME}
EOF
