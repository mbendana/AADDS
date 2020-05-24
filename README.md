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

The script also installs the following required packages:\
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

STEPS:
1. On the Ubuntu VM, create a new .sh file with Nano or Vi(m). Examples:\
nano join.sh\
vi join.sh\
vim join.sh

2. Copy and paste the content of script UbuntuVMJoin.sh onto the newly created .sh file

3. Save the file:\
If Nano: Ctrl + X > Yes > Enter\
If Vi or Vim: Esc > :wq > Enter

3. Make the file executable:\
chmod +x join.sh

4. Run the file:\
./join.sh

During script execution, prompts for entering the AAD DS managed instance domain name (Example: aaddscontoso.com) and the username of the admin user joining the VM to the managed instance (Example: admin) will appear.

A prompt for entering the password of the admin user will also show.
