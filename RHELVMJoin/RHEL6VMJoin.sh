#!/bin/bash

#This script is to join a RHEL 6 VM to an AADDS managed instance as shown at:
#https://docs.microsoft.com/en-us/azure/active-directory-domain-services/join-rhel-linux-vm
#Author: Milton Halton

#Get the domain name in a variable
read -p "Please enter the managed instance domain name (Example: aaddscontoso.com): " domainName
echo ""

#Modify /etc/hosts file with 127.0.0.1 rhel rhel.aaddscontoso.com
hostsFile="127.0.0.1 $( echo $(hostname) $(hostname).$domainName | tr '[:upper:]' '[:lower:]')"
grepHostsFile=`sudo grep "$hostsFile" /etc/hosts`
#Checking hosts file
if [[ "$grepHostsFile" == *"$hostsFile"* ]]
then
	echo "====================="
	echo "/etc/hosts file already contains entry"
	echo "====================="
	sudo grep --color=always "$hostsFile" /etc/hosts
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
echo "Installing required packages adcli sssd authconfig krb5-workstation"
echo "====================="
sudo yum -y install adcli sssd authconfig krb5-workstation
echo ""

#Get the admin user who will join the VM to the managed instance
read -p "Please enter the domain admin name (Example: admin): " domainAdmin
echo ""

#discover the realm
echo "====================="
echo "Discovering the realm"
echo "====================="
sudo adcli info $domainName
echo ""

#Join the VM
echo "====================="
echo "Joining the VM to the AAD DS managed instance"
echo "====================="
sudo adcli join $domainName -U $domainAdmin
echo ""

#Modify the /etc/krb5.conf
echo "====================="
echo "Modifying the /etc/krb5.conf file"
echo "====================="
echo "
[logging]
 default = FILE:/var/log/krb5libs.log
 kdc = FILE:/var/log/krb5kdc.log
 admin_server = FILE:/var/log/kadmind.log

[libdefaults]
 default_realm = ${domainName^^}
 dns_lookup_realm = true
 dns_lookup_kdc = true
 ticket_lifetime = 24h
 renew_lifetime = 7d
 forwardable = true

[realms]
 ${domainName^^} = {
 kdc = ${domainName^^}
 admin_server = ${domainName^^}
 }

[domain_realm]
 .${domainName^^} = ${domainName^^}
 ${domainName^^} = ${domainName^^}" | sudo tee /etc/krb5.conf
 echo ""
 
 #Modify the /etc/sssd/sssd.conf file
 echo "====================="
echo "Modifying the /etc/sssd/sssd.conf file"
echo "====================="
echo "
[sssd]
 services = nss, pam, ssh, autofs
 config_file_version = 2
 domains = ${domainName^^}

[domain/${domainName^^}]

 id_provider = ad" | sudo tee /etc/sssd/sssd.conf
 echo ""

#Modify file /etc/sssd/sssd.conf permissions to 600 and owner:group to root:root
echo "====================="
echo "Modifying file /etc/sssd/sssd.conf permissions to 600 and owner:group to root:root"
echo "====================="
sudo chmod 600 /etc/sssd/sssd.conf
sudo chown root:root /etc/sssd/sssd.conf
echo ""

#Use authconfig to instruct the VM about the AD Linux integration
echo "====================="
echo "Using authconfig to instruct the VM about the AD Linux integration"
echo "====================="
sudo authconfig --enablesssd --enablesssdauth --update
echo ""

#Start and enable the sssd service
echo "====================="
echo "Starting and enabling the sssd service"
echo "====================="
sudo service sssd start
sudo chkconfig sssd on
echo ""

#Query user AD information using getent
echo "====================="
echo "Querying user AD information using getent"
echo "====================="
sudo getent passwd $domainAdmin
echo ""

#Modify the /etc/ssh/sshd_config file with PasswordAuthentication yes
sshFile="PasswordAuthentication yes"
grepSshFile=`sudo grep "^$sshFile" /etc/ssh/sshd_config`
#Checking sshd_config file
if [[ "$grepSshFile" == *"$sshFile"* ]]
then
	echo "====================="
	echo "/etc/ssh/sshd_config file already contains entry"
	echo "====================="
	sudo grep --color=always "$sshFile" /etc/ssh/sshd_config
	echo ""
else
	sudo sed -i -r "s/^(#|)PasswordAuthentication ((n|N)o|yes)/$sshdFile/" /etc/ssh/sshd_config
	echo "====================="
	echo "Modified /etc/ssh/sshd_config file"
	echo "====================="
	sudo grep --color=always "$sshFile" /etc/ssh/sshd_config
	echo ""
	#Restart the ssh service
	echo "====================="
	echo "Restarting the ssh service"
	echo "====================="
	sudo service sshd restart
	echo ""
fi

#Modify /etc/sudoers file with "# Add 'AAD DC Administrators' group members as admins." & "%AAD\ DC\ Administrators ALL=(ALL) NOPASSWD:ALL"
sudoersFile="%AAD\ DC\ Administrators@$domainName ALL=(ALL) NOPASSWD:ALL"
grepSudoersFile=`sudo grep -F "$sudoersFile" /etc/sudoers`
#Checking sudoers file
if [[ "$grepSudoersFile" == *"$sudoersFile"* ]]
then
	echo "====================="
	echo "/etc/sudoers file already contains entry"
	echo "====================="
	sudo grep -F --color=always "$sudoersFile" /etc/sudoers
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
