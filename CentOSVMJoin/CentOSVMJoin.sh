#!/bin/bash

#This script is to join a CentOS VM to an AADDS managed instance as shown at:
#https://docs.microsoft.com/en-us/azure/active-directory-domain-services/join-centos-linux-vm
#Author: Milton Halton

#Get the domain name in a variable
read -p "Please enter the managed instance domain name (Example: aaddscontoso.com): " domainName
echo ""

#Modify /etc/hosts file with 127.0.0.1 centos.aaddscontoso.com centos
hostsFile="127.0.0.1 $( echo $(hostname).$domainName $(hostname) | tr '[:upper:]' '[:lower:]')"
grepHostsFile=`sudo cat /etc/hosts | grep "$hostsFile"`
#Checking hosts file
if [[ "$grepHostsFile" == *"$hostsFile"* ]]
then
	echo "====================="
	echo "/etc/hosts file already contains entry"
	echo "====================="
	sudo cat /etc/hosts | grep "$hostsFile" --color=always
	echo ""
else
	sudo sed -i -r "/^127.0.0.1/i $hostsFile" /etc/hosts
	echo "====================="
	echo "Modified /etc/hosts file"
	echo "====================="
	sudo cat /etc/hosts | grep "$hostsFile" --color=always
	echo ""
fi

#Install required components
echo "====================="
echo "Installing required packages realmd sssd krb5-workstation krb5-libs oddjob oddjob-mkhomedir samba-common-tools"
echo "====================="
sudo yum -y install realmd sssd krb5-workstation krb5-libs oddjob oddjob-mkhomedir samba-common-tools
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
sudo realm join --verbose ${domainName^^} -U "$domainAdmin@${domainName^^}"
echo ""

#Modify the /etc/ssh/sshd_config file with PasswordAuthentication yes
sshFile="PasswordAuthentication yes"
grepSshFile=`sudo cat /etc/ssh/sshd_config | grep "^$sshFile"`
#Checking sshd_config file
if [[ "$grepSshFile" == *"$sshFile"* ]]
then
	echo "====================="
	echo "/etc/ssh/sshd_config file already contains entry"
	echo "====================="
	sudo cat /etc/ssh/sshd_config | grep "$sshFile" --color=always
	echo ""
else
	sudo sed -i -r "s/^(#|)PasswordAuthentication ((n|N)o|yes)/$sshdFile/" /etc/ssh/sshd_config
	echo "====================="
	echo "Modified /etc/ssh/sshd_config file"
	echo "====================="
	sudo cat /etc/ssh/sshd_config | grep "$sshFile" --color=always
	echo ""
	#Restart the ssh service
	echo "====================="
	echo "Restarting the ssh service"
	echo "====================="
	sudo systemctl restart sshd
	echo ""
fi

#Modify /etc/sudoers file with "# Add 'AAD DC Administrators' group members as admins." & "%AAD\ DC\ Administrators ALL=(ALL) NOPASSWD:ALL"
sudoersFile="%AAD\ DC\ Administrators@$domainName ALL=(ALL) NOPASSWD:ALL"
grepSudoersFile=`sudo cat /etc/sudoers | grep -F "$sudoersFile"`
#Checking sudoers file
if [[ "$grepSudoersFile" == *"$sudoersFile"* ]]
then
	echo "====================="
	echo "/etc/sudoers file already contains entry"
	echo "====================="
	sudo cat /etc/sudoers | grep -F "$sudoersFile" --color=always
	echo ""
else
	echo "# Add 'AAD DC Administrators' group members as admins." | sudo tee -a /etc/sudoers
	echo "$sudoersFile" | sudo tee -a /etc/sudoers
	echo "====================="
	echo "Modified /etc/sudoers file"
	echo "====================="
	sudo cat /etc/sudoers | grep -F "$sudoersFile" --color=always
	echo ""
fi

#Sign in with the domain admin user
echo "====================="
echo "Signing with the domain admin user"
echo "====================="
ssh -l $domainAdmin@$domainName $(hostname).$domainName
echo ""
