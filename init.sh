#!/bin/bash

## Following code can help in setting up AMI in AWS for practice of DevOps Tools 
export PATH="/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin:/root/.local/bin:/root/bin"
## Common Functions 
cp common-funs.sh /tmp/common.sh
source /tmp/common.sh
case $ELV in 
    el7) EPEL=https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm ;;
    el8) EPEL=https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm ;;
esac

## Check ROOT USER 
if [ $(id -u) -ne 0 ]; then 
    error "You should be a root/sudo user to perform this script"
    exit 1
fi

## Disabling SELINUX
sed -i -e '/^SELINUX/ c SELINUX=disabled' /etc/selinux/config

## Disable firewall 
systemctl disable firewalld &>/dev/null

## Remove cockpit message 
yum remove insights-client -y
rm -f /etc/motd.d/insights-client

## Perform OS Update
yum install vim https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm net-tools bind-utils sshpass jq nmap telnet -y

## Fixing SSH timeouts
sed -i -e '/TCPKeepAlive/ c TCPKeepAlive no' -e '/ClientAliveInterval/ c ClientAliveInterval 10' -e '/ClientAliveCountMax/ c ClientAliveCountMax 240'  /etc/ssh/sshd_config

## Profile Environment
cp ps1.sh /etc/profile.d/ps1.sh
cp env /etc/profile.d/boot-env.sh
cp profile /etc/profile
chmod +x /etc/profile /etc/profile.d/*

useradd ec2-user
mkdir -p /home/ec2-user/.ssh
chown ec2-user:ec2-user /home/ec2-user/.ssh
chmod 700 /home/ec2-user/.ssh

echo "@reboot passwd -u ec2-user" >>/var/spool/cron/root
chmod 600 /var/spool/cron/root

## Enable Password Logins
sed -i -e '/^PasswordAuthentication/ c PasswordAuthentication yes' -e '/^PermitRootLogin/ c PermitRootLogin yes' /etc/ssh/sshd_config /etc/ssh/sshd_config.d/50-cloud-init.conf


## Setup user passwords
ROOT_PASS="DevOps321"
CENTOS_PASS="DevOps321"

echo "echo $ROOT_PASS | passwd --stdin root"   >>/etc/rc.d/rc.local 
echo "echo $CENTOS_PASS | passwd --stdin ec2-user"   >>/etc/rc.d/rc.local
echo "sed -i -e 's/^ec2-user:!!/ec2-user:/' /etc/shadow" >>/etc/rc.d/rc.local
chmod +x /etc/rc.d/rc.local

echo
echo 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCuHVsHPaU+hcgeYkPdn3Ww6dIFRSEDT76NMctGhZgO1jy14OI+K74Z1sDYQ92TyV3+5rXJdXixrO60BE2QSK/h3TCARHYlkyjjoUbMNd3T6HBn4bH7dtOGfWAHQlr3sKn5vkzQyFCF3w+ZC0i3TvvLpjvPdvIwmrUa+VTx+Hq3wuzepGsr9DMJk8scktYg6AUmk2V0JLZjehGxU0dD4rv86CVgHnzT3VMrDxy22YdO+jjIn0qnVuSbMuntrAiHd5Q5Ru0OTz0DJMAcRVqgprmHmCtwEhncIVN95uIEPsXE89Q9/GmlsKszOBvmx42VRhzXKMCER57vj3xDRZaori90TTNkjbzpDkWK0s2JCsm0XSaaF0i6kMFCdEM37NDA/txe4pSodM47Fqq7kVeJXfYV9dmlmHDSCk1Kuruz5cyORcllISAe5BCG8wuoCtEsjPRB/E1x+aO87mUMEOqxfpP+f6TVYgUBh7aOJfAnXg8fRIMBM91D9KXGAE70X+rT++c= ec2-user@ip-172-31-47-186.ec2.internal' >/home/ec2-user/.ssh/authorized_keys
echo 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCzCnlZC5ZsYsrrv9ys7hLAfPPtpWUK3eHFLbFiotwORE8/+jqHoxxTQd8qTEKeKtMVNqEJBuhCkH2PzrEOg6b9wrq28QhwpgeLJZn5VAATMU5ArKnzDxLZ1/NJt5qYZSotwOxHArCbf4Uib9MW/nhcENxownRK19Rva7gk/zcwBhyBqfIpWZRzrRAVVxOctwTEd7XnTgZ7AKYo3CZyvPRlpuRbZ8YCav1Ny+sNgQw+qQ4cmxjVpYhWbWGzmVIKlOUKXHgAOVyJpN/KNhOnhhxXtAnxvTLjdG9PQFc8oQFqfZVpN2st650wlJWlk9xDqlAj08/lcXkJ9g4sdIwIULhWpV0OiHfQZJh1izDpwD60/5cequoPt40F6VwM8cNpsTdeHof31aPCsJnX5AqhtHzwujpOAqjSb33Keyvn5hk+3Dsq2xzNgoOWw0fjbCXir6exVwy4cp0P0tJTQxufN2rgo3L+LF9m6kkAkLAGxlaWFMJuYSaE04iaHIQShyT7aUs= root@ip-172-31-47-186.ec2.internal' >>/root/.ssh/authorized_keys
chmod -R 700 /root/.ssh/id_rsa*
chmod -R 700 /home/ec2-user/.ssh/id_rsa*

sed -i -e 's/showfailed//' /etc/pam.d/postlogin
sed -i -e '4 i colorscheme desert' /etc/vimrc

echo 'ec2-user ALL=(ALL) NOPASSWD:ALL' >/etc/sudoers.d/ec2-user
chattr +i /etc/ssh/sshd_config /etc/ssh/sshd_config.d/50-cloud-init.conf /etc/sudoers.d/ec2-user

cp ssh_config /etc/ssh/ssh_config.d/04-ssh-config.conf
cp motd /etc/motd

## Create directory for journalctl failure
mkdir -p /var/log/journal
curl -L -o /tmp/install-snoopy.sh https://github.com/a2o/snoopy/raw/install/install/install-snoopy.sh
bash /tmp/install-snoopy.sh stable && rm -f /tmp/install-snoopy.sh

## Remove Amazon SSM & CFN
rpm -e amazon-ssm-agent
unlink /etc/init.d/cfn-hup

## Disable GPG Checks by default
sed -i -e '/gpgcheck/ c gpgcheck=0' /etc/dnf/dnf.conf

## Keep the logs clean.
echo ':programname, isequal, "systemd-sysv-generator" /var/log/sysv.log
:programname, isequal, "/usr/sbin/irqbalance" /var/log/irq.log
& stop' >/etc/rsyslog.d/01-sysv.conf

# Commands to /bin
cp set-hostname.sh /bin/set-hostname
cp mysql_secure_installation /usr/sbin/mysql_secure_installation
chmod +x /bin/set-hostname /usr/sbin/mysql_secure_installation

# Install AWS CLI
cd /tmp
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip &>/dev/null
/tmp/aws/install
/usr/local/bin/aws --version || true

yum clean all &>/dev/null
rm -rf /var/lib/yum/*  /tmp/*
sed -i -e '/aws-hostname/ d' -e '$ a r /tmp/aws-hostname' /usr/lib/tmpfiles.d/tmp.conf

# Empty All log files
truncate -s 0 `find /var/log -type f |xargs`

rm -rf /tmp/*
