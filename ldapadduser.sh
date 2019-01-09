#!/bin/bash
set -u

CONFIG_FILE=$HOME/.ntuhpcldap.conf
if [ ! -f $CONFIG_FILE ]; then
	echo "Config file ${CONFIG_FILE} doesn't exist!"
	exit 1
fi
. $CONFIG_FILE

if [ "$#" -ne 3 ]; then
	echo 'Usage: ldapadduser.sh <username> <email> <surname>'
	exit 1
fi

USERNAME=$1
EMAIL=$2
SURNAME=$3

echo -n Enter LDAP admin password:
read -s LDAP_PASSWD
echo

LIST_OF_USERS=`ldapsearch -x -D "${LDAP_BIND_DN}" -w ${LDAP_PASSWD} -b "dc=ntuhpc,dc=org" -H "${LDAP_SERVER}" -s sub "objectClass=posixAccount"`
if echo "${LIST_OF_USERS}" | grep -q ${USERNAME}; then
	echo "User ${USERNAME} already exists!"
	exit 1
fi

LARGEST_UID=`echo "${LIST_OF_USERS}" | grep uidNumber | cut -d" " -f2 | sort | tail -n 1`
UIDNUMBER=`expr ${LARGEST_UID} + 1`
DEFAULT_GROUP=2000
PASSWD_CLEAR=`curl -s "https://www.passwordrandom.com/query?command=password"`
PASSWD=`slappasswd -s ${PASSWD_CLEAR}`


ldapadd -x -D "${LDAP_BIND_DN}" -w ${LDAP_PASSWD} -H "${LDAP_SERVER}" > /dev/null << EOF && echo User ${USERNAME} added, initial password: ${PASSWD_CLEAR}
dn: cn=${USERNAME},ou=people,dc=ntuhpc,dc=org
objectClass: person
objectClass: organizationalPerson
objectClass: inetOrgPerson
objectClass: top
objectClass: posixAccount
cn: ${USERNAME}
gidNumber: ${DEFAULT_GROUP}
homeDirectory: /home/${USERNAME}
sn: ${SURNAME}
uid: ${USERNAME}
uidNumber: ${UIDNUMBER}
loginShell: /bin/bash
mail: ${EMAIL}
userPassword: ${PASSWD}
EOF

curl -s --user "api:${MAILGUN_KEY}" \
	https://api.mailgun.net/v3/mail.ntuhpc.org/messages \
	-F from='NTUHPC Info <info@mail.ntuhpc.org>' \
	-F to=${EMAIL} \
	-F subject="[NTUHPC] Your LDAP account information" \
	-F text="Your NTUHPC LDAP account has been created.

Username: ${USERNAME}
Password: ${PASSWD_CLEAR}
		  
Please change your password at https://ldapreset.ntuhpc.org"
