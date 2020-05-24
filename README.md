This script is to join an Ubuntu VM to an AADDS managed instance by automatically configuring everything found at:
https://docs.microsoft.com/en-us/azure/active-directory-domain-services/join-ubuntu-linux-vm

The script has been tested on Ubuntu 16.04.6 LTS and 18.04.4 LTS versions.

As per the doc, the script makes modifications to the following files:\
/etc/hosts\
/etc/ntp.conf\
/etc/krb5.conf\
/etc/sssd/sssd.conf\
/etc/ssh/sshd_config\
/etc/pam.d/common-session\
/etc/sudoers

The script also install the following required packages:\
krb5-user\
samba\
sssd\
sssd-tools\
libnss-sss\
libpam-sss\
ntp\
ntpdate\
realmd\
adcli
