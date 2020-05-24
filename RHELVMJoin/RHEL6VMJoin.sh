#!/bin/bash

#This script is to join a RHEL 6 VM to an AADDS managed instance as shown at:
#https://docs.microsoft.com/en-us/azure/active-directory-domain-services/join-rhel-linux-vm

#Get the domain name in a variable
read -p "Please enter the managed instance domain name (Example: aaddscontoso.com): " domainName
echo ""

#Modify /etc/hosts file with 127.0.0.1 rhel rhel.aaddscontoso.com
echo "Modifying the /etc/hosts file"
sudo sed -i -r "/^127.0.0.1/i 127.0.0.1 $( echo $(hostname) $(hostname).$domainName | tr '[:upper:]' '[:lower:]')" /etc/hosts
echo "grep output from /etc/hosts file"
sudo cat /etc/hosts | grep 127.0.0.1
echo ""

#Install required components
echo "Installing required packages adcli sssd authconfig krb5-workstation"
sudo yum -y install adcli sssd authconfig krb5-workstation
echo ""

#Get the admin user who will join the VM to the managed instance
read -p "Please enter the domain admin name (Example: admin): " domainAdmin
echo ""

#discover the realm
echo "Discovering the realm"
sudo adcli info $domainName
echo ""

#Join the VM
echo "Joining the VM to the AAD DS managed instance"
sudo adcli join $domainName -U $domainAdmin
echo ""

#Modify the /etc/krb5.conf
echo "Modifying the /etc/krb5.conf file"
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
echo "Modifying the /etc/sssd/sssd.conf file"
echo "
[sssd]
 services = nss, pam, ssh, autofs
 config_file_version = 2
 domains = ${domainName^^}

[domain/${domainName^^}]

 id_provider = ad" | sudo tee /etc/sssd/sssd.conf
 echo ""

#Modify file /etc/sssd/sssd.conf permissions to 600 and owner:group to root:root
echo "Modifying file /etc/sssd/sssd.conf permissions to 600 and owner:group to root:root" 
sudo chmod 600 /etc/sssd/sssd.conf
sudo chown root:root /etc/sssd/sssd.conf
echo ""

#Use authconfig to instruct the VM about the AD Linux integration
echo "Using authconfig to instruct the VM about the AD Linux integration"
sudo authconfig --enablesssd --enablesssdauth --update
echo ""

#Start and enable the sssd service
echo "Starting and enabling the sssd service"
sudo service sssd start
sudo chkconfig sssd on
echo ""

#Query user AD information using getent
echo "Querying user AD information using getent"
sudo getent passwd $domainAdmin
echo ""

#Modify the /etc/ssh/sshd_config file with PasswordAuthentication yes
echo "Modifying the /etc/ssh/sshd_config file"
sudo sed -i -r 's/^(PasswordAuthentication (n|N)o|#PasswordAuthentication (n|N)o|#PasswordAuthentication yes)/PasswordAuthentication yes/' /etc/ssh/sshd_config
echo "grep output from /etc/ssh/sshd_config file"
sudo cat /etc/ssh/sshd_config | grep 'PasswordAuthentication yes'
echo ""

#Restart the ssh service
echo "Restarting the ssh service"
sudo service sshd restart
echo ""

#Modify /etc/sudoers file with "# Add 'AAD DC Administrators' group members as admins." & "%AAD\ DC\ Administrators ALL=(ALL) NOPASSWD:ALL"
echo "Modifying the /etc/sudoers file"
echo "# Add 'AAD DC Administrators' group members as admins." | sudo tee -a /etc/sudoers
echo "%AAD\ DC\ Administrators@$domainName ALL=(ALL) NOPASSWD:ALL" | sudo tee -a /etc/sudoers
echo "grep output from /etc/sudoers file"
sudo cat /etc/sudoers | grep 'AAD[\] DC[\] Administrators'
echo ""

#Sign in with the domain admin user
echo "Signing with the domain admin user"
ssh -l $domainAdmin@$domainName $(hostname).$domainName
echo ""