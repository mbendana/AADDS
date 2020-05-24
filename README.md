# [THIS SCRIPT HASN'T BEEN TESTED YET]

These scripts are to join CentOS VMs to an AADDS managed instance by automatically configuring everything found at:
https://docs.microsoft.com/en-us/azure/active-directory-domain-services/join-centos-linux-vm

As per the doc, the script makes modifications to the following files:\
/etc/hosts\
/etc/ssh/sshd_config\
/etc/sudoers

The script also installs the following required packages:\
realmd\
sssd\
krb5-workstation\
krb5-libs\
oddjob\
oddjob-mkhomedir\
samba-common-tools

---

**STEPS:**
1. On the CentOS VM, create a new .sh file with Nano or Vi(m).\
Examples:\
nano centos.sh\
vi centos.sh\
vim centos.sh

2. Copy and paste the content of script CentOSVMJoin.sh onto the newly created .sh file

3. Save the file:\
If Nano: Ctrl + X > Yes > Enter\
If Vi or Vim: Esc > :wq > Enter

3. Make the file executable:\
chmod +x centos.sh

4. Run the file:\
./centos.sh

During script execution, prompts for entering the AAD DS managed instance domain name (Example: aaddscontoso.com) and the username of the admin user joining the VM to the managed instance (Example: admin) will appear.

A prompt for entering the password of the admin user will also show.
