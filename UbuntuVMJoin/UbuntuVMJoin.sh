#This script is to join an Ubuntu VM to an AADDS managed instance as shown at:
#https://docs.microsoft.com/en-us/azure/active-directory-domain-services/join-ubuntu-linux-vm

#Get the domain name in a variable
read -p "Please enter the managed instance domain name (Example: example.com): " domainName

#Get VM name
computerName=hostname

#Modify /etc/hosts file
sudo echo "127.0.0.1 $(hostname).$domainName $(hostname)" | tr '[:upper:]' '[:lower:]' >> hosts
#Actual file is:
#sudo echo "127.0.0.1 $(hostname).$domainName $(hostname)" | tr '[:upper:]' '[:lower:]' >> /etc/hosts

#Install required components
#sudo apt-get update
#sudo apt-get install krb5-user samba sssd sssd-tools libnss-sss libpam-sss ntp ntpdate realmd adcli

#Modify the /etc/ntp.conf file
sudo echo "server $domainName" >> ntp.conf
#Actual file is:
#sudo echo "server $domainName" >> /etc/ntp.conf

#Stop, update and start the ntp service
#sudo systemctl stop ntp
#sudo ntpdate $domainName
#sudo systemctl start ntp

#discover the realm
#sudo realm discover ${domainName^^}

#Get the admin user who will join the VM to the managed instance and initialize the process
read -p "Please enter the domain admin name (Example: admin): " domainAdmin
#kinit $domainAdmin@${domainName^^}

#Join the VM
#sudo realm join --verbose ${domainName^^} -U "$domainAdmin@${domainName^^}" --install=/

#Modify the /etc/krb5.conf file
sudo echo "rdns=false" >> krb5.conf
#Actual file is:
#sudo echo "rdns=false" >> /etc/krb5.conf

#Modify the /etc/sssd/sssd.conf file
sudo sed -i -r 's/^use_fully_qualified_names = True/#use_fully_qualified_names = True/' sssd.conf
#Actual file is:
#sudo sed -i -r 's/use_fully_qualified_names = True/#use_fully_qualified_names = True/' /etc/sssd/sssd.conf

#Restart the sssd service
#sudo service sssd restart

#Modify the /etc/ssh/sshd_config file
sudo sed -i -r 's/^(PasswordAuthentication (n|N)o|#PasswordAuthentication (n|N)o|#PasswordAuthentication yes)/PasswordAuthentication yes/' sshd_config
#Actual file is:
#sudo sed -i -r 's/^(PasswordAuthentication (n|N)o|#PasswordAuthentication (n|N)o|#PasswordAuthentication yes)/PasswordAuthentication yes/' sshd_config /etc/ssh/sshd_config

#Restart the ssh service
#sudo systemctl restart ssh

#Modify the /etc/pam.d/common-session file
sudo echo "session required pam_mkhomedir.so skel=/etc/skel/ umask=0077" >> common-session
#Actual file is:
#sudo echo "session required pam_mkhomedir.so skel=/etc/skel/ umask=0077" >> /etc/pam.d/common-session

#Modify /etc/sudoers file
#sudo echo "# Add 'AAD DC Administrators' group members as admins." >> sudoers
#sudo echo "%AAD\ DC\ Administrators ALL=(ALL) NOPASSWD:ALL" >> sudoers
#Actual file is:
#sudo echo "# Add 'AAD DC Administrators' group members as admins." >> /etc/sudoers
#sudo echo "%AAD\ DC\ Administrators ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

#Sign in with the admin user
ssh -l $domainAdmin@$domainName $(hostname).$domainName