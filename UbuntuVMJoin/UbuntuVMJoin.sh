#!/bin/bash

#This script is to join an Ubuntu VM to an AADDS managed instance as shown at:
#https://docs.microsoft.com/en-us/azure/active-directory-domain-services/join-ubuntu-linux-vm
#Author: Milton Halton

#Get the domain name in a variable
read -p "Please enter the managed instance domain name (Example: aaddscontoso.com): " domainName
echo ""

#Modify /etc/hosts file with 127.0.0.1 ubuntu.aaddscontoso.com ubuntu
hostsFile="127.0.0.1 $( echo $(hostname).$domainName $(hostname) | tr '[:upper:]' '[:lower:]')"
grepHostsFile=`sudo grep "$hostsFile" /etc/hosts`
#Checking hosts file
if [[ "$grepHostsFile" == *"$hostsFile"* ]]
then
	echo "====================="
	echo "/etc/hosts file already contains entry"
	echo "====================="
	sudo grep --color=always "$grepHostsFile" /etc/hosts 
	echo ""
else
	sudo sed -i -r "1 i $hostsFile" /etc/hosts
	echo "====================="
	echo "Modified /etc/hosts file"
	echo "====================="
	sudo grep --color=always "$hostsFile" /etc/hosts
	echo ""
fi

#Install required components
echo "====================="
echo "Installing required packages: krb5-user samba sssd sssd-tools libnss-sss libpam-sss ntp ntpdate realmd adcli"
echo "====================="
sudo apt-get update
sudo apt-get --assume-yes install krb5-user samba sssd sssd-tools libnss-sss libpam-sss ntp ntpdate realmd adcli
echo ""

#Modify the /etc/ntp.conf file with server aaddscontoso.com
ntpFile="server $domainName"
grepNtpFile=`sudo grep "$ntpFile" /etc/ntp.conf`
#Checking ntp.conf file
if [[ "$grepNtpFile" == *"$ntpFile"* ]]
then
	echo "====================="
	echo "/etc/ntp.conf file already contains entry"
	echo "====================="
	sudo grep --color=always "$grepNtpFile" /etc/ntp.conf
	echo ""
else
	sudo sed -i -r "1 i $ntpFile" /etc/ntp.conf
	echo "====================="
	echo "Modified /etc/ntp.conf file"
	echo "====================="
	sudo grep --color=always "$ntpFile" /etc/ntp.conf
	echo ""
fi

#Stop, update and start the ntp service
echo "====================="
echo "Stopping, updating and starting the ntp service"
echo "====================="
sudo systemctl stop ntp
sudo ntpdate $domainName
sudo systemctl start ntp
echo ""

#Get the admin user who will join the VM to the managed instance
read -p "Please enter the domain admin name (Example: admin): " domainAdmin
echo ""

#discover the realm
echo "====================="
echo "Discovering the realm"
echo "====================="
sudo realm discover ${domainName^^}
echo ""

#Initialize the kinit process
echo "====================="
echo "Starting the kinit process"
echo "====================="
kinit $domainAdmin@${domainName^^}
echo ""

#Join the VM
echo "====================="
echo "Joining the VM to the AAD DS managed instance"
echo "====================="
sudo realm join --verbose ${domainName^^} -U "$domainAdmin@${domainName^^}" --install=/
echo ""

#Modify the /etc/krb5.conf file with rdns=false
krbFile="rdns=false"
grepKrbFile=`sudo grep "$krbFile" /etc/krb5.conf`
#Checking ntp.conf file
if [[ "$grepKrbFile" == *"$krbFile"* ]]
then
	echo "====================="
	echo "/etc/krb5.conf file already contains entry"
	echo "====================="
	sudo grep --color=always "$grepKrbFile" /etc/krb5.conf
	echo ""
else
	sudo sed -i -r "/default_realm/a \\\t$krbFile" /etc/krb5.conf
	echo "====================="
	echo "Modified /etc/krb5.conf file"
	echo "====================="
	sudo grep --color=always "$krbFile" /etc/krb5.conf
	echo ""
fi

#Start the sssd service
echo "====================="
echo "Starting the sssd service"
echo "====================="
sudo service sssd start
echo ""

#Modify the /etc/sssd/sssd.conf file with # use_fully_qualified_names = True
sssdFile="use_fully_qualified_names = True"
grepSssdFile=`sudo grep "^#.*$sssdFile" /etc/sssd/sssd.conf`
#Checking ntp.conf file
if [[ "$grepSssdFile" == *"$sssdFile"* ]]
then
	echo "====================="
	echo "/etc/sssd/sssd.conf file already contains entry"
	echo "====================="
	sudo grep --color=always "$grepSssdFile" /etc/sssd/sssd.conf
	echo ""
else
	sudo sed -i -r "s/use_fully_qualified_names = True/#$sssdFile/" /etc/sssd/sssd.conf
	echo "====================="
	echo "Modified /etc/sssd/sssd.conf file"
	echo "====================="
	sudo grep --color=always "#$sssdFile" /etc/sssd/sssd.conf
	echo ""
	#Restart the sssd service
	echo "====================="
	echo "Restarting the sssd service"
	echo "====================="
	sudo service sssd restart
	echo ""
fi

#Modify the /etc/ssh/sshd_config file with PasswordAuthentication yes
sshdFile="PasswordAuthentication yes"
grepSshdFile=`sudo grep "^$sshdFile" /etc/ssh/sshd_config`
#Checking ntp.conf file
if [[ "$grepSshdFile" == *"$sshdFile"* ]]
then
	echo "====================="
	echo "/etc/ssh/sshd_config file already contains entry"
	echo "====================="
	sudo grep --color=always "$grepSshdFile" /etc/ssh/sshd_config
	echo ""
else
	sudo sed -i -r "s/^(#|)PasswordAuthentication ((n|N)o|yes)/$sshdFile/" /etc/ssh/sshd_config
	echo "====================="
	echo "Modified /etc/ssh/sshd_config file"
	echo "====================="
	sudo grep --color=always "$sshdFile" /etc/ssh/sshd_config
	echo ""
	#Restart the ssh service
	echo "====================="
	echo "Restarting the ssh service"
	echo "====================="
	sudo systemctl restart ssh
	echo ""
fi

#Modify the /etc/pam.d/common-session file with session required pam_mkhomedir.so skel=/etc/skel/ umask=0077
pamFile="session required pam_mkhomedir.so skel=/etc/skel/ umask=0077"
grepPamFile=`sudo grep "$pamFile" /etc/pam.d/common-session`
#Checking ntp.conf file
if [[ "$grepPamFile" == *"$pamFile"* ]]
then
	echo "====================="
	echo "/etc/pam.d/common-session file already contains entry"
	echo "====================="
	sudo grep --color=always "$grepPamFile" /etc/pam.d/common-session
	echo ""
else
	sudo sed -i -r "/pam_sss.so/a $pamFile" /etc/pam.d/common-session
	echo "====================="
	echo "Modified /etc/pam.d/common-session  file"
	echo "====================="
	sudo cat /etc/pam.d/common-session| grep "$pamFile" --color=always
	echo ""
fi

#Modify /etc/sudoers file with "# Add 'AAD DC Administrators' group members as admins." & "%AAD\ DC\ Administrators ALL=(ALL) NOPASSWD:ALL"
sudoersFile="%AAD\ DC\ Administrators ALL=(ALL) NOPASSWD:ALL"
grepSudoersFile=`sudo grep -F "$sudoersFile" /etc/sudoers`
#Checking sudoers file
if [[ "$grepSudoersFile" == *"$sudoersFile"* ]]
then
	echo "====================="
	echo "/etc/sudoers file already contains entry"
	echo "====================="
	sudo grep -F --color=always "$grepSudoersFile" /etc/sudoers
	echo ""
else
	echo "# Add 'AAD DC Administrators' group members as admins." | sudo tee -a /etc/sudoers
	echo "$sudoersFile" | sudo tee -a /etc/sudoers
	echo "====================="
	echo "Modified /etc/sudoers file"
	echo "====================="
	sudo grep -F --color=always "$sudoersFile" /etc/sudoers
	echo ""
fi

#Sign in with the domain admin user
echo "====================="
echo "Signing with the domain admin user"
echo "====================="
ssh -l $domainAdmin@$domainName $(hostname).$domainName
echo ""
