These scripts are to join RHEL 7/6 VMs to an AADDS managed instance by automatically configuring everything found at:
https://docs.microsoft.com/en-us/azure/active-directory-domain-services/join-rhel-linux-vm

The scripts have been tested with RHEL 7.3, 7.4, 7.7 and 6.9 versions.

As per the doc, the script makes modifications to the following files:\
**On RHEL 7:**\
/etc/hosts\
/etc/ssh/sshd_config\
/etc/sudoers

**On RHEL 6:**\
/etc/hosts\
/etc/krb5.conf\
/etc/sssd/sssd.conf\
/etc/ssh/sshd_config\
/etc/sudoers

The script also installs the following required packages:\
**On RHEL 7:**\
realmd\
sssd\
krb5-workstation\
krb5-libs\
oddjob\
oddjob-mkhomedir\
samba-common-tools

**On RHEL 6:**\
adcli\
sssd\
authconfig\
krb5-workstation

---

**STEPS:**
1. On the RHEL (7/6) VM, create a new .sh file with Nano or Vi(m).\
Examples:
```console
nano rhel.sh
vi rhel.sh
vim rhel.sh
```

2. Copy and paste the content of script RHEL(7/6)VMJoin.sh onto the newly created .sh file

3. Save the file:\
If Nano: Ctrl + X > Yes > Enter\
If Vi or Vim: Esc > :wq > Enter

4. Make the file executable:
```console
chmod +x rhel.sh
```

5. Run the file:
```console
./rhel.sh
```

During script execution, prompts for entering the AAD DS managed instance domain name (Example: aaddscontoso.com) and the username of the admin user joining the VM to the managed instance (Example: admin) will appear.

A prompt for entering the password of the admin user will also show.
