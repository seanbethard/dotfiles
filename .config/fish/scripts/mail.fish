#!/usr/bin/env fish
source $mc

set status DRAFT

:"
mail_server
├── etc
│   ├── apt
│   │   └── sources.list.d
│   │       └── rspamd.list
│   ├── dovecot
│   │   ├── conf.d
│   │   │   ├── 10-auth.conf
│   │   │   ├── 10-mail.conf
│   │   │   ├── 10-master.conf
│   │   │   ├── 10-ssl.conf
│   │   │   ├── 15-mailboxes.conf
│   │   │   ├── 20-imap.conf
│   │   │   ├── 20-lmtp.conf
│   │   │   ├── 20-managesieve.conf
│   │   │   ├── 20-sieve.conf
│   │   │   ├── 90-quota.conf
│   │   │   └── 90-sieve.conf
│   │   ├── dovecot-dict-sql.conf.ext
│   │   └── dovecot-sql.conf.ext
│   ├── nginx
│   │   └── sites-enabled
│   │       └── mail.site.com
│   ├── postfix
│   │   ├── master.cf
│   │   └── sql
│   │       ├── mysql_virtual_alias_domain_catchall_maps.cf
│   │       ├── mysql_virtual_alias_domain_mailbox_maps.cf
│   │       ├── mysql_virtual_alias_domain_maps.cf
│   │       ├── mysql_virtual_alias_maps.cf
│   │       ├── mysql_virtual_domains_maps.cf
│   │       └── mysql_virtual_mailbox_maps.cf
│   ├── rspamd
│   │   └── local.d
│   │       ├── classifier-bayes.conf
│   │       ├── dkim_signing.conf
│   │       ├── milter_headers.conf
│   │       ├── worker-controller.inc
│   │       ├── worker-normal.inc
│   │       └── worker-proxy.inc
│   └── ssl
│       └── certs
│           └── dhparams.pem
├── usr
│   └── local
│       └── bin
│           └── quota-warning.sh
└── var
    ├── lib
    │   └── rspamd
    │       └── dkim
    │           └── mail.pub
    ├── vmail
    │   └── mail
    │       └── sieve
    │           └── global
    │               ├── report-ham.sieve
    │               ├── report-spam.sieve
    │               └── spam-global.sieve
    └── www
        └── postfixadmin
            ├── config.inc.php
            └── config.local.php
"

# set up mail server: DKIM, rspamadm, MariaDB, Roundcube
# requirements:
#     domains: example.com, mail.example.com, SMTP port access
#     DNS: MX record, A record, AAAA record, glue records, reverse DNS records 
#     versioning: ubuntu 22.04, PHP 8.1, PostfixAdmin 3.3.13, Roundcube 1.6.5
#     credentials:
#         root_pw
#         postfix_db
#         postfix_pw
#         superadmin
#         superadmin_pw
#         security_email
#         encrypted_rspam_pw
#         webmail_db
#         webmail_pw
#     dhparams

# create a Diffie-Hellman group
openssl dhparam -out /etc/ssl/certs/dhparam.pem 4096

# mailboxes are stored in the system users home directory
groupadd -g 5000 vmail
useradd -u 5000 -g vmail -s /usr/sbin/nologin -d /var/mail/vmail -m vmail

# install required packages
apt install nginx mariadb-server php-fpm php-cli php-imap php-json php-mysql php-opcache php-mbstring php-readline python3-certbot-nginx postfix postfix-mysql dovecot-imapd dovecot-lmtpd dovecot-pop3d dovecot-mysql redis-server rspamd php-intl php-mail-mime php-net-smtp php-net-socket php-pear php-xml php-intl php-xml php-gd php-gd php-imagick dovecot-sieve dovecot-managesieved
-y

# set root database pw
mysql_secure_installation

#Switch to unix_socket authentication [Y/n] y
#Change the root password? [Y/n] y
#Set root password? [Y/n] y
#New password: root_pw
#Re-enter new password: root_pw
#Remove anonymous users? [Y/n] y
#Disallow root login remotely? [Y/n] y
#Remove test database and access to it? [Y/n] y
#Reload privilege tables now? [Y/n] y

# unpack PostfixAdmin 3.3.13
wget https://github.com/postfixadmin/postfixadmin/archive/refs/tags/postfixadmin-3.3.13.tar.gz
tar xzf postfixadmin-3.3.13.tar.gz
mv postfixadmin-postfix-admin-3.3.13/ /var/www/postfixadmin
rm -f postfixadmin-3.3.13.tar.gz
mkdir /var/www/postfixadmin/templates_c
chown -R www-data: /var/www/postfixadmin

# connect to database Server
mysql -u root -p
mysql -e "CREATE DATABASE postfixadmin"
mysql -e "GRANT ALL ON postfixadmin.* TO 'postfixadmin'@'localhost' IDENTIFIED BY 'postfix_pw'"
mysql -e "FLUSH PRIVILEGES"
mysql -e EXIT

# file: config.local.php
# location: /var/www/postfixadmin
#     define login credentials
#     define default aliases
#     disable fetchmail
#     enable quota
:"
<?php
$CONF['configured'] = true;

$CONF['database_type'] = 'mysqli';
$CONF['database_host'] = 'localhost';
$CONF['database_user'] = 'postfixadmin';
$CONF['database_password'] = 'postfix_pw';
$CONF['database_name'] = 'postfix_db';

$CONF['default_aliases'] = array (
'abuse'      => 'abuse@site.com',
'hostmaster' => 'hostmaster@site.com',
'postmaster' => 'postmaster@site.com',
'webmaster'  => 'webmaster@site.com',
'security'   => 'cso@site.com'
);

$CONF['fetchmail'] = 'NO';
$CONF['show_footer_text'] = 'NO';

$CONF['quota'] = 'YES';
$CONF['domain_quota'] = 'YES';
$CONF['quota_multiplier'] = '1024000';
$CONF['used_quotas'] = 'YES';
$CONF['new_quota_table'] = 'YES';

$CONF['aliases'] = '0';
$CONF['mailboxes'] = '0';
$CONF['maxquota'] = '0';
$CONF['domain_quota_default'] = '0';
?>
"

# install schema
sudo -u www-data php /var/www/postfixadmin/public/upgrade.php

# create superadmin
bash /var/www/postfixadmin/scripts/postfixadmin-cli admin add

#Admin: superadmin
#Password: superadmin_pw
#Password (again): superadmin_pw
#Super admin: y
#Domain: mail.site.com
#Active: y

# create nginx files for mail.site.com
rm /etc/nginx/sites-available/default /etc/nginx/sites-enabled/default

# file: mail.site.com.conf
# location: /etc/nginx/sites-enabled
:"
server {
    listen 80;
    server_name mail.site.com;
    root /var/www;

    location / {
    try_files $uri $uri/ /index.php;
    }

    location /postfixadmin {
    index index.php;
    try_files $uri $uri/ /postfixadmin/public/login.php;
    }

    location ~* \.php$ {
        fastcgi_split_path_info ^(.+?\.php)(/.*)$;
        if (!-f $document_root$fastcgi_script_name) {return 404;}
        fastcgi_pass  unix:/run/php/php8.1-fpm.sock;
        fastcgi_index index.php;
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
    }
}
"

# activate new config
service nginx restart

# create certificate for mail.site.com
certbot --nginx -v

# create directory for database config files
mkdir -p /etc/postfix/sql

mysql_virtual_domains_maps.cf
:"
user = postfixadmin
password = postfix_pw
hosts = 127.0.0.1
dbname = postfixadmin
query = SELECT domain FROM domain WHERE domain='%s' AND active = '1'
"

mysql_virtual_mailbox_maps.cf
:"
user = postfixadmin
password = postfix_pw
hosts = 127.0.0.1
dbname = postfixadmin
query = SELECT maildir FROM mailbox WHERE username='%s' AND active = '1'

"

mysql_virtual_alias_maps.cf
:"
user = postfixadmin
password = postfix_pw
hosts = 127.0.0.1
dbname = postfixadmin
query = SELECT goto FROM alias WHERE address='%s' AND active = '1'
"

mysql_virtual_alias_domain_maps.cf
:"
user = postfixadmin
password = postfix_pw
hosts = 127.0.0.1
dbname = postfixadmin
query = SELECT goto FROM alias,alias_domain WHERE alias_domain.alias_domain = '%d' and alias.address = CONCAT('%u', '@', alias_domain.target_domain) AND alias.active = 1 AND alias_domain.active='1'
"

mysql_virtual_alias_domain_catchall_maps.cf
:"
user = postfixadmin
password = postfix_pw
hosts = 127.0.0.1
dbname = postfixadmin
query  = SELECT goto FROM alias,alias_domain WHERE alias_domain.alias_domain = '%d' and alias.address = CONCAT('@', alias_domain.target_domain) AND alias.active = 1 AND alias_domain.active='1'
"

mysql_virtual_alias_domain_mailbox_maps.cf
:"
user = postfixadmin
password = postfix_pw
hosts = 127.0.0.1
dbname = postfixadmin
query = SELECT maildir FROM mailbox,alias_domain WHERE alias_domain.alias_domain = '%d' and mailbox.username = CONCAT('%u', '@', alias_domain.target_domain) AND mailbox.active = 1 AND alias_domain.active='1'
"

# update Postfix config with database config files
postconf -e "virtual_mailbox_domains = mysql:/etc/postfix/sql/mysql_virtual_domains_maps.cf"
postconf -e "virtual_alias_maps = mysql:/etc/postfix/sql/mysql_virtual_alias_maps.cf, mysql:/etc/postfix/sql/mysql_virtual_alias_domain_maps.cf, mysql:/etc/postfix/sql/mysql_virtual_alias_domain_catchall_maps.cf"
postconf -e "virtual_mailbox_maps = mysql:/etc/postfix/sql/mysql_virtual_mailbox_maps.cf, mysql:/etc/postfix/sql/mysql_virtual_alias_domain_mailbox_maps.cf"

# Dovecot server delivers mail to local mailboxes
postconf -e "virtual_transport = lmtp:unix:private/dovecot-lmtp"

# set up TLS with SSL cert (this may be incomplete)
postconf -e 'smtp_tls_security_level = may'
postconf -e 'smtpd_tls_security_level = may'
postconf -e 'smtp_tls_note_starttls_offer = yes'
postconf -e 'smtpd_tls_loglevel = 1'
postconf -e 'smtpd_tls_received_header = yes'
postconf -e 'smtpd_tls_cert_file = /etc/letsencrypt/live/mail.site.com/fullchain.pem'
postconf -e 'smtpd_tls_key_file = /etc/letsencrypt/live/mail.site.com/privkey.pem'

# set up SMTP (this may require an additional resouce, saslauthd)
postconf -e 'smtpd_sasl_type = dovecot'
postconf -e 'smtpd_sasl_path = private/auth'
postconf -e 'smtpd_sasl_local_domain ='
postconf -e 'smtpd_sasl_security_options = noanonymous'
postconf -e 'broken_sasl_auth_clients = yes'
postconf -e 'smtpd_sasl_auth_enable = yes'
postconf -e 'smtpd_recipient_restrictions = permit_sasl_authenticated,permit_mynetworks,reject_unauth_destination'

# enable TLS/SSL and submission ports
# file: master.cf
# location: /etc/postfix
:"
#
# Postfix master process configuration file.  For details on the format
# of the file, see the master(5) manual page (command: "man 5 master" or
# on-line: http://www.postfix.org/master.5.html).
#
# Do not forget to execute "postfix reload" after editing this file.
#
# ==========================================================================
# service type  private unpriv  chroot  wakeup  maxproc command + args
#               (yes)   (yes)   (no)    (never) (100)
# ==========================================================================
smtp      inet  n       -       y       -       -       smtpd
#smtp      inet  n       -       y       -       1       postscreen
#smtpd     pass  -       -       y       -       -       smtpd
#dnsblog   unix  -       -       y       -       0       dnsblog
#tlsproxy  unix  -       -       y       -       0       tlsproxy
# Choose one: enable submission for loopback clients only, or for any client.
#127.0.0.1:submission inet n -   y       -       -       smtpd
submission inet n       -       y       -       -       smtpd
  -o syslog_name=postfix/submission
  -o smtpd_tls_security_level=encrypt
  -o smtpd_sasl_auth_enable=yes
#  -o smtpd_tls_auth_only=yes
#  -o smtpd_reject_unlisted_recipient=no
#  -o smtpd_client_restrictions=$mua_client_restrictions
#  -o smtpd_helo_restrictions=$mua_helo_restrictions
#  -o smtpd_sender_restrictions=$mua_sender_restrictions
#  -o smtpd_recipient_restrictions=
#  -o smtpd_relay_restrictions=permit_sasl_authenticated,reject
  -o milter_macro_daemon_name=ORIGINATING
# Choose one: enable smtps for loopback clients only, or for any client.
#127.0.0.1:smtps inet n  -       y       -       -       smtpd
smtps     inet  n       -       y       -       -       smtpd
  -o syslog_name=postfix/smtps
  -o smtpd_tls_wrappermode=yes
  -o smtpd_sasl_auth_enable=yes
#  -o smtpd_reject_unlisted_recipient=no
#  -o smtpd_client_restrictions=$mua_client_restrictions
#  -o smtpd_helo_restrictions=$mua_helo_restrictions
#  -o smtpd_sender_restrictions=$mua_sender_restrictions
#  -o smtpd_recipient_restrictions=
#  -o smtpd_relay_restrictions=permit_sasl_authenticated,reject
  -o milter_macro_daemon_name=ORIGINATING
#628       inet  n       -       y       -       -       qmqpd
pickup    unix  n       -       y       60      1       pickup
cleanup   unix  n       -       y       -       0       cleanup
qmgr      unix  n       -       n       300     1       qmgr
#qmgr     unix  n       -       n       300     1       oqmgr
tlsmgr    unix  -       -       y       1000?   1       tlsmgr
rewrite   unix  -       -       y       -       -       trivial-rewrite
bounce    unix  -       -       y       -       0       bounce
defer     unix  -       -       y       -       0       bounce
trace     unix  -       -       y       -       0       bounce
verify    unix  -       -       y       -       1       verify
flush     unix  n       -       y       1000?   0       flush
proxymap  unix  -       -       n       -       -       proxymap
proxywrite unix -       -       n       -       1       proxymap
smtp      unix  -       -       y       -       -       smtp
relay     unix  -       -       y       -       -       smtp
        -o syslog_name=postfix/$service_name
#       -o smtp_helo_timeout=5 -o smtp_connect_timeout=5
showq     unix  n       -       y       -       -       showq
error     unix  -       -       y       -       -       error
retry     unix  -       -       y       -       -       error
discard   unix  -       -       y       -       -       discard
local     unix  -       n       n       -       -       local
virtual   unix  -       n       n       -       -       virtual
lmtp      unix  -       -       y       -       -       lmtp
anvil     unix  -       -       y       -       1       anvil
scache    unix  -       -       y       -       1       scache
postlog   unix-dgram n  -       n       -       1       postlogd
#
# ====================================================================
# Interfaces to non-Postfix software. Be sure to examine the manual
# pages of the non-Postfix software to find out what options it wants.
#
# Many of the following services use the Postfix pipe(8) delivery
# agent.  See the pipe(8) man page for information about ${recipient}
# and other message envelope options.
# ====================================================================
#
# maildrop. See the Postfix MAILDROP_README file for details.
# Also specify in main.cf: maildrop_destination_recipient_limit=1
#
maildrop  unix  -       n       n       -       -       pipe
  flags=DRXhu user=vmail argv=/usr/bin/maildrop -d ${recipient}
#
# ====================================================================
#
# Recent Cyrus versions can use the existing "lmtp" master.cf entry.
#
# Specify in cyrus.conf:
#   lmtp    cmd="lmtpd -a" listen="localhost:lmtp" proto=tcp4
#
# Specify in main.cf one or more of the following:
#  mailbox_transport = lmtp:inet:localhost
#  virtual_transport = lmtp:inet:localhost
#
# ====================================================================
#
# Cyrus 2.1.5 (Amos Gouaux)
# Also specify in main.cf: cyrus_destination_recipient_limit=1
#
#cyrus     unix  -       n       n       -       -       pipe
#  flags=DRX user=cyrus argv=/cyrus/bin/deliver -e -r ${sender} -m ${extension} ${user}
#
# ====================================================================
# Old example of delivery via Cyrus.
#
#old-cyrus unix  -       n       n       -       -       pipe
#  flags=R user=cyrus argv=/cyrus/bin/deliver -e -m ${extension} ${user}
#
# ====================================================================
#
# See the Postfix UUCP_README file for configuration details.
#
uucp      unix  -       n       n       -       -       pipe
  flags=Fqhu user=uucp argv=uux -r -n -z -a$sender - $nexthop!rmail ($recipient)
#
# Other external delivery methods.
#
ifmail    unix  -       n       n       -       -       pipe
  flags=F user=ftn argv=/usr/lib/ifmail/ifmail -r $nexthop ($recipient)
bsmtp     unix  -       n       n       -       -       pipe
  flags=Fq. user=bsmtp argv=/usr/lib/bsmtp/bsmtp -t$nexthop -f$sender $recipient
scalemail-backend unix -       n       n       -       2       pipe
  flags=R user=scalemail argv=/usr/lib/scalemail/bin/scalemail-store ${nexthop} ${user} ${extension}
mailman   unix  -       n       n       -       -       pipe
  flags=FRX user=list argv=/usr/lib/mailman/bin/postfix-to-mailman.py ${nexthop} ${user}
"

# restart postfix
service postfix restart


# configure IMAP server

# file: dovecot-sql.conf.ext
# location: /etc/dovecot
:"
-       y       -       0       dnsblog
#tlsproxy  unix  -       -       y       -       0       tlsproxy
# Choose one: enable submission for loopback clients only, or for any client.
#127.0.0.1:submission inet n -   y       -       -       smtpd
submission inet n       -       y       -       -       smtpd
-o syslog_name=postfix/submission
-o smtpd_tls_security_level=encrypt
-o smtpd_sasl_auth_enable=yes
#  -o smtpd_tls_auth_only=yes
#  -o smtpd_reject_unlisted_recipient=no
#  -o smtpd_client_restrictions=$mua_client_restrictions
#  -o smtpd_helo_restrictions=$mua_helo_restrictions
#  -o smtpd_sender_restrictions=$mua_sender_restrictions
#  -o smtpd_recipient_restrictions=
#  -o smtpd_relay_restrictions=permit_sasl_authenticated,reject
-o milter_macro_daemon_name=ORIGINATING
# Choose one: enable smtps for loopback clients only, or for any client.
#127.0.0.1:smtps inet n  -       y       -       -       smtpd
smtps     inet  n       -       y       -       -       smtpd
-o syslog_name=postfix/smtps
-o smtpd_tls_wrappermode=yes
-o smtpd_sasl_auth_enable=yes
#  -o smtpd_reject_unlisted_recipient=no
#  -o smtpd_client_restrictions=$mua_client_restrictions
#  -o smtpd_helo_restrictions=$mua_helo_restrictions
#  -o smtpd_sender_restrictions=$mua_sender_restrictions
#  -o smtpd_recipient_restrictions=
#  -o smtpd_relay_restrictions=permit_sasl_authenticated,reject
-o milter_macro_daemon_name=ORIGINATING
#628       inet  n       -       y       -       -       qmqpd
pickup    unix  n       -       y       60      1       pickup
cleanup   unix  n       -       y       -       0       cleanup
qmgr      unix  n       -       n       300     1       qmgr
#qmgr     unix  n       -       n       300     1       oqmgr
tlsmgr    unix  -       -       y       1000?   1       tlsmgr
rewrite   unix  -       -       y       -       -       trivial-rewrite
bounce    unix  -       -       y       -       0       bounce
defer     unix  -       -       y       -       0       bounce
trace     unix  -       -       y       -       0       bounce
verify    unix  -       -       y       -       1       verify
flush     unix  n       -       y       1000?   0       flush
proxymap  unix  -       -       n       -       -       proxymap
proxywrite unix -       -       n       -       1       proxymap
smtp      unix  -       -       y       -       -       smtp
relay     unix  -       -       y       -       -       smtp
-o syslog_name=postfix/$service_name
#       -o smtp_helo_timeout=5 -o smtp_connect_timeout=5
showq     unix  n       -       y       -       -       showq
error     unix  -       -       y       -       -       error
retry     unix  -       -       y       -       -       error
discard   unix  -       -       y       -       -       discard
local     unix  -       n       n       -       -       local
virtual   unix  -       n       n       -       -       virtual
lmtp      unix  -       -       y       -       -       lmtp
anvil     unix  -       -       y       -       1       anvil
scache    unix  -       -       y       -       1       scache
postlog   unix-dgram n  -       n       -       1       postlogd
#
# ====================================================================
# Interfaces to non-Postfix software. Be sure to examine the manual
# pages of the non-Postfix software to find out what options it wants.
#
# Many of the following services use the Postfix pipe(8) delivery
# agent.  See the pipe(8) man page for information about ${recipient}
# and other message envelope options.
# ====================================================================
#
# maildrop. See the Postfix MAILDROP_README file for details.
# Also specify in main.cf: maildrop_destination_recipient_limit=1
#
maildrop  unix  -       n       n       -       -       pipe
flags=DRXhu user=vmail argv=/usr/bin/maildrop -d ${recipient}
#
# ====================================================================
#
# Recent Cyrus versions can use the existing "lmtp" master.cf entry.
#
# Specify in cyrus.conf:
#   lmtp    cmd="lmtpd -a" listen="localhost:lmtp" proto=tcp4
#
# Specify in main.cf one or more of the following:
#  mailbox_transport = lmtp:inet:localhost
#  virtual_transport = lmtp:inet:localhost
#
# ====================================================================
#
# Cyrus 2.1.5 (Amos Gouaux)
# Also specify in main.cf: cyrus_destination_recipient_limit=1
#
#cyrus     unix  -       n       n       -       -       pipe
#  flags=DRX user=cyrus argv=/cyrus/bin/deliver -e -r ${sender} -m ${extension} ${user}
#
# ====================================================================
# Old example of delivery via Cyrus.
#
#old-cyrus unix  -       n       n       -       -       pipe
#  flags=R user=cyrus argv=/cyrus/bin/deliver -e -m ${extension} ${user}
#
# ====================================================================
#
# See the Postfix UUCP_README file for configuration details.
#
uucp      unix  -       n       n       -       -       pipe
flags=Fqhu user=uucp argv=uux -r -n -z -a$sender - $nexthop!rmail ($recipient)
#
# Other external delivery methods.
#
ifmail    unix  -       n       n       -       -       pipe
flags=F user=ftn argv=/usr/lib/ifmail/ifmail -r $nexthop ($recipient)
bsmtp     unix  -       n       n       -       -       pipe
flags=Fq. user=bsmtp argv=/usr/lib/bsmtp/bsmtp -t$nexthop -f$sender $recipient
scalemail-backend unix -       n       n       -       2       pipe
flags=R user=scalemail argv=/usr/lib/scalemail/bin/scalemail-store ${nexthop} ${user} ${extension}
mailman   unix  -       n       n       -       -       pipe
flags=FRX user=list argv=/usr/lib/mailman/bin/postfix-to-mailman.py ${nexthop} ${user}
root@super-duty-tough-work ~#
File Edit Options Buffers Tools Conf Help
root@super-duty-tough-work ~# service postfix restart
root@super-duty-tough-work ~# emacs /etc/dovecot/dovecot-sql.conf.ext
root@super-duty-tough-work ~# mkdir mail_server/etc/dovecot
root@super-duty-tough-work ~# cp /etc/dovecot/dovecot-sql.conf.ext mail_server/etc/dovecot/
root@super-duty-tough-work ~# cat /etc/dovecot/dovecot-sql.conf.ext
# This file is commonly accessed via passdb {} or userdb {} section in
# conf.d/auth-sql.conf.ext

# This file is opened as root, so it should be owned by root and mode 0600.
#
# http://wiki2.dovecot.org/AuthDatabase/SQL
#
# For the sql passdb module, you'll need a database with a table that
# contains fields for at least the username and password. If you want to
# use the user@domain syntax, you might want to have a separate domain
# field as well.
#
# If your users all have the same uig/gid, and have predictable home
# directories, you can use the static userdb module to generate the home
# dir based on the username and domain. In this case, you won't need fields
# for home, uid, or gid in the database.
#
# If you prefer to use the sql userdb module, you'll want to add fields
# for home, uid, and gid. Here is an example table:
#
# CREATE TABLE users (
#     username VARCHAR(128) NOT NULL,
#     domain VARCHAR(128) NOT NULL,
#     password VARCHAR(64) NOT NULL,
#     home VARCHAR(255) NOT NULL,
#     uid INTEGER NOT NULL,
#     gid INTEGER NOT NULL,
#     active CHAR(1) DEFAULT 'Y' NOT NULL
# );

# Database driver: mysql, pgsql, sqlite
driver = mysql

# Database connection string. This is driver-specific setting.
#
# HA / round-robin load-balancing is supported by giving multiple host
# settings, like: host=sql1.host.org host=sql2.host.org
#
# pgsql:
#   For available options, see the PostgreSQL documentation for the
#   PQconnectdb function of libpq.
#   Use maxconns=n (default 5) to change how many connections Dovecot can
#   create to pgsql.
#
# mysql:
#   Basic options emulate PostgreSQL option names:
#     host, port, user, password, dbname
#
#   But also adds some new settings:
#     client_flags           - See MySQL manual
#     connect_timeout        - Connect timeout in seconds (default: 5)
#     read_timeout           - Read timeout in seconds (default: 30)
#     write_timeout          - Write timeout in seconds (default: 30)
#     ssl_ca, ssl_ca_path    - Set either one or both to enable SSL
#     ssl_cert, ssl_key      - For sending client-side certificates to server
#     ssl_cipher             - Set minimum allowed cipher security (default: HIGH)
#     ssl_verify_server_cert - Verify that the name in the server SSL certificate
#                              matches the host (default: no)
#     option_file            - Read options from the given file instead of
#                              the default my.cnf location
#     option_group           - Read options from the given group (default: client)
#
#   You can connect to UNIX sockets by using host: host=/var/run/mysql.sock
#   Note that currently you can't use spaces in parameters.
#
# sqlite:
#   The path to the database file.
#
# Examples:
#   connect = host=192.168.1.1 dbname=users
#   connect = host=sql.example.com dbname=virtual user=virtual password=blarg
#   connect = /etc/dovecot/authdb.sqlite
#
connect = host=127.0.0.1 dbname=postfixadmin user=postfixadmin password=your_secret_password

# Default password scheme.
#
# List of supported schemes is in
# http://wiki2.dovecot.org/Authentication/PasswordSchemes
#
default_pass_scheme = MD5-CRYPT

# passdb query to retrieve the password. It can return fields:
#   password - The user's password. This field must be returned.
#   user - user@domain from the database. Needed with case-insensitive lookups.
#   username and domain - An alternative way to represent the "user" field.
#
# The "user" field is often necessary with case-insensitive lookups to avoid
# e.g. "name" and "nAme" logins creating two different mail directories. If
# your user and domain names are in separate fields, you can return "username"
# and "domain" fields instead of "user".
#
# The query can also return other fields which have a special meaning, see
# http://wiki2.dovecot.org/PasswordDatabase/ExtraFields
#
# Commonly used available substitutions (see http://wiki2.dovecot.org/Variables
# for full list):
#   %u = entire user@domain
#   %n = user part of user@domain
#   %d = domain part of user@domain
#
# Note that these can be used only as input to SQL query. If the query outputs
# any of these substitutions, they're not touched. Otherwise it would be
# difficult to have eg. usernames containing '%' characters.
#
# Example:
#   password_query = SELECT userid AS user, pw AS password \
    #     FROM users WHERE userid = '%u' AND active = 'Y'
    #
    #password_query = \
	#  SELECT username, domain, password \
	#  FROM users WHERE username = '%n' AND domain = '%d'

    # userdb query to retrieve the user information. It can return fields:
    #   uid - System UID (overrides mail_uid setting)
    #   gid - System GID (overrides mail_gid setting)
    #   home - Home directory
    #   mail - Mail location (overrides mail_location setting)
    #
    # None of these are strictly required. If you use a single UID and GID, and
    # home or mail directory fits to a template string, you could use userdb static
    # instead. For a list of all fields that can be returned, see
    # http://wiki2.dovecot.org/UserDatabase/ExtraFields
    #
    # Examples:
    #   user_query = SELECT home, uid, gid FROM users WHERE userid = '%u'
    #   user_query = SELECT dir AS home, user AS uid, group AS gid FROM users where userid = '%u'
    #   user_query = SELECT home, 501 AS uid, 501 AS gid FROM users WHERE userid = '%u'
    #
    #user_query = \
	#  SELECT home, uid, gid \
	#  FROM users WHERE username = '%n' AND domain = '%d'
	user_query = SELECT CONCAT('/var/mail/vmail/',maildir) AS home, \
	    CONCAT('maildir:/var/mail/vmail/',maildir) AS mail, \
	    5000 AS uid, 5000 AS gid, CONCAT('*:bytes=',quota) AS quota_rule \
	    FROM mailbox WHERE username = '%u' AND active = 1

	# If you wish to avoid two SQL lookups (passdb + userdb), you can use
	# userdb prefetch instead of userdb sql in dovecot.conf. In that case you'll
	# also have to return userdb fields in password_query prefixed with "userdb_"
	# string. For example:
	#password_query = \
	    #  SELECT userid AS user, password, \
	    #    home AS userdb_home, uid AS userdb_uid, gid AS userdb_gid \
	    #  FROM users WHERE userid = '%u'
	    password_query = SELECT username AS user,password FROM mailbox \
		WHERE username = '%u' AND active='1'

	    # Query to get a list of all usernames.
	    iterate_query = SELECT username AS user FROM mailbox~
"

# file: 10-auth.conf
# file: 10-mail.conf
# file: 10-master.conf
# file: 10-ssl.conf
# file: 15-mailboxes.conf
# file: 20-imap.conf
# file: 20-lmtp.conf
# file: 90-quota.conf

# warn users when their mailbox is full
# file: quota-warning.sh
# location: /usr/local/bin
:"
#!/bin/sh
PERCENT=$1
USER=$2
cat << EOF | /usr/lib/dovecot/dovecot-lda -d $USER -o "plugin/quota=dict:User quota::noenforcing:proxy::sqlquota"
From: postmaster@example.com
Subject: Quota warning

Your mailbox is $PERCENT% full!
Backup old messages to continue to receive mail.
EOF
"
chmod +x /usr/local/bin/quota-warning.sh

# install rspamd 
wget -O- https://rspamd.com/apt-stable/gpg.key | apt-key add -
echo "deb http://rspamd.com/apt-stable/ $(lsb_release -cs) main" | tee -a /etc/apt/sources.list.d/rspamd.list

# file: worker-normal.inc
# location: /etc/rspamd/local.d 
bind_socket = "127.0.0.1:11333"

# file: worker-proxy.inc
# location: /etc/rspamd/local.d
# ...

rspamadm pw --encrypt -p encrypted_rspamd_pw

service rspamd restart
service dovecot restart

mkdir -p /var/vmail/mail/sieve/global

# compile sieve scripts
sievec /var/vmail/mail/sieve/global/spam-global.sieve
sievec /var/vmail/mail/sieve/global/report-spam.sieve
sievec /var/vmail/mail/sieve/global/report-ham.sieve
chown -R vmail: /var/vmail/mail/sieve/

# create DKIM key pair
mkdir /var/lib/rspamd/dkim/
rspamadm dkim_keygen -b 2048 -s mail -k /var/lib/rspamd/dkim/mail.key >/var/lib/rspamd/dkim/mail.pub

# file: dkim_signing.conf
:"
selector = "mail";
path = "/var/lib/rspamd/dkim/$selector.key";
allow_username_mismatch = true;
"

# add support for ARC signatures
cp /etc/rspamd/local.d/dkim_signing.conf /etc/rspamd/local.d/arc.conf

# add key as TXT record
cat /var/lib/rspamd/dkim/mail.pub

# set up webmail
mysql -u root -p

CREATE DATABASE roundcubemail
GRANT ALL ON roundcubemail.* TO 'roundcube'@'localhost' IDENTIFIED BY your_secret_password
FLUSH PRIVILEGES
\q

# install roundcube 1.6.5
# php-intl may require a specific version of libicu
# php-intl is necessary to configure webmail
wget https://github.com/roundcube/roundcubemail/releases/download/1.6.5/roundcubemail-1.6.5-complete.tar.gz
tar xzf roundcubemail-1.6.5-complete.tar.gz
mv roundcubemail-1.6.5 /var/www/webmail
rm roundcubemail-1.6.5-complete.tar.gz
chown -R www-data: /var/www/webmail

# restart webserver
service nginx restart

# configure webmail at https://mail.site.com/webmail/installer/

# remove the installer
rm -rf /var/www/roundcubemail/installer
