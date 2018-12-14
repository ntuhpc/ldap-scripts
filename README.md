# NTU HPC LDAP scripts

> A collection of scripts for LDAP user & group management

## Usage

Create a config file at `$HOME/.ntuhpcldap.conf` and put the following content inside

```
LDAP_SERVER=<ldap-server-address>
LDAP_BIND_DN=<ldap-bind-dn>
MAILGUN_KEY=<mailgun-key>
```

For example,

```
LDAP_SERVER=ldaps://example.com:8880
LDAP_BIND_DN=cn=user,dc=example,dc=com
MAILGUN_KEY=xxxxxx
```
