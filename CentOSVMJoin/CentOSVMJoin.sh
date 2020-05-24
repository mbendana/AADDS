#!/bin/bash

#This script is to join a CentOS VM to an AADDS managed instance as shown at:
#https://docs.microsoft.com/en-us/azure/active-directory-domain-services/join-centos-linux-vm
#Author: Milton Halton

#Get the domain name in a variable
read -p "Please enter the managed instance domain name (Example: aaddscontoso.com): " domainName
echo ""

#Modify /etc/hosts file with 127.0.0.1 centos.aaddscontoso.com centos
echo "Modifying the /etc/hosts file"
sudo sed -i -r "/^127.0.0.1/i 127.0.0.1 $( echo $(hostname).$domainName $(hostname) | tr '[:upper:]' '[:lower:]')" /etc/hosts
echo "grep output from /etc/hosts file"
sudo cat /etc/hosts | grep 127.0.0.1
echo ""

#Install required components
echo "Installing required packages realmd sssd krb5-workstation krb5-libs oddjob oddjob-mkhomedir samba-common-tools"
sudo yum -y install realmd sssd krb5-workstation krb5-libs oddjob oddjob-mkhomedir samba-common-tools
echo ""

#Get the admin user who will join the VM to the managed instance
read -p "Please enter the domain admin name (Example: admin): " domainAdmin
echo ""

#discover the realm
echo "Discovering the realm"
sudo realm discover ${domainName^^}
echo ""

#Initialize the kinit process
echo "Starting the kinit process"
kinit $domainAdmin@${domainName^^}
echo ""

#Join the VM
echo "Joining the VM to the AAD DS managed instance"
sudo realm join --verbose ${domainName^^} -U "$domainAdmin@${domainName^^}"
echo ""

#Modify the /etc/ssh/sshd_config file with PasswordAuthentication yes
echo "Modifying the /etc/ssh/sshd_config file"
sudo sed -i -r 's/^(PasswordAuthentication (n|N)o|#PasswordAuthentication (n|N)o|#PasswordAuthentication yes)/PasswordAuthentication yes/' /etc/ssh/sshd_config
echo "grep output from /etc/ssh/sshd_config file"
sudo cat /etc/ssh/sshd_config | grep 'PasswordAuthentication yes'
echo ""

#Restart the ssh service
echo "Restarting the ssh service"
sudo systemctl restart sshd
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