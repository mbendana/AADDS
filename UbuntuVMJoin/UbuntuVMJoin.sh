#This script is to join an Ubuntu VM to an AADDS managed instance as shown at:
#https://docs.microsoft.com/en-us/azure/active-directory-domain-services/join-ubuntu-linux-vm

#Get the domain name in a variable
read -p "Please enter the managed instance domain name (Example: example.com): " domainName
sudo echo ""

#Modify /etc/hosts file with 127.0.0.1 ubuntu.aaddscontoso.com ubuntu
sudo sed -i -r "/^127.0.0.1 localhost/i 127.0.0.1 $( echo $(hostname).$domainName $(hostname) | tr '[:upper:]' '[:lower:]')" /etc/hosts
sudo echo "grep output from /etc/hosts file"
sudo cat /etc/hosts | grep 127.0.0.1
sudo echo ""

#Install required components
sudo apt-get update
sudo apt-get install krb5-user samba sssd sssd-tools libnss-sss libpam-sss ntp ntpdate realmd adcli
sudo echo ""

#Modify the /etc/ntp.conf file with server aaddscontoso.com
sudo sed -i -r "1 i server $domainName" /etc/ntp.conf
sudo echo "grep output from /etc/ntp.conf file"
sudo cat /etc/ntp.conf | grep server
sudo echo ""

#Stop, update and start the ntp service
sudo echo "Stopping, updating and starting the ntp service"
sudo systemctl stop ntp
sudo ntpdate $domainName
sudo systemctl start ntp
sudo echo ""

#discover the realm
sudo echo "Discovering the realm"
sudo realm discover ${domainName^^}
sudo echo ""

#Get the admin user who will join the VM to the managed instance
read -p "Please enter the domain admin name (Example: admin): " domainAdmin
sudo echo ""

#Initialize the kinit process
sudo echo "Starting the kinit process"
kinit $domainAdmin@${domainName^^}
sudo echo ""

#Join the VM
sudo echo "Joining the VM to the AAD DS managed instance"
sudo realm join --verbose ${domainName^^} -U "$domainAdmin@${domainName^^}" --install=/
sudo echo ""

#Modify the /etc/krb5.conf file with rdns=false
sudo sed -i -r "/default_realm/a \\\trdns=false" /etc/krb5.conf
sudo echo "grep output from /etc/krb5.conf file"
sudo cat /etc/krb5.conf | grep rdns
sudo echo ""

#Modify the /etc/sssd/sssd.conf file with # use_fully_qualified_names = True
sudo sed -i -r 's/use_fully_qualified_names = True/#use_fully_qualified_names = True/' /etc/sssd/sssd.conf
sudo echo "grep output from /etc/sssd/sssd.conf file"
sudo cat /etc/sssd/sssd.conf | grep use_fully_qualified_names
sudo echo ""

#Restart the sssd service
sudo echo "Restarting the sssd service"
sudo service sssd restart
sudo echo ""

#Modify the /etc/ssh/sshd_config file with PasswordAuthentication yes
sudo sed -i -r 's/^(PasswordAuthentication (n|N)o|#PasswordAuthentication (n|N)o|#PasswordAuthentication yes)/PasswordAuthentication yes/' /etc/ssh/sshd_config
sudo echo "grep output from /etc/ssh/sshd_config file"
sudo cat /etc/ssh/sshd_config | grep 'PasswordAuthentication yes'
sudo echo ""

#Restart the ssh service
sudo echo "Restarting the ssh service"
sudo systemctl restart ssh
sudo echo ""

#Modify the /etc/pam.d/common-session file with session required pam_mkhomedir.so skel=/etc/skel/ umask=0077
sudo sed -i -r '/pam_sss.so/a session required pam_mkhomedir.so skel=/etc/skel/ umask=0077' /etc/pam.d/common-session
sudo echo "grep output from /etc/pam.d/common-session file"
sudo cat /etc/pam.d/common-session | grep 'session required pam_mkhomedir.so skel=/etc/skel/ umask=0077'
sudo echo ""

#Modify /etc/sudoers file with "# Add 'AAD DC Administrators' group members as admins." & "%AAD\ DC\ Administrators ALL=(ALL) NOPASSWD:ALL"
sudo echo "# Add 'AAD DC Administrators' group members as admins." >> /etc/sudoers
sudo echo "%AAD\ DC\ Administrators ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
sudo echo "grep output from /etc/sudoers file"
sudo cat /etc/sudoers | grep 'AAD[\] DC[\] Administrators'
sudo echo ""

#Sign in with the domain admin user
sudo echo "Signing with the domain admin user"
ssh -l $domainAdmin@$domainName $(hostname).$domainName
sudo echo ""