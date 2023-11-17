# The currently running kernel version is 5.15.0-78-generic
# which is not the expected kernel version 5.15.0-88-generic.

# create user with SSH privileges
adduser sb
usermod -aG sudo sb

# set up firewall
ufw allow "Nginx OpenSSH"
ufw allow "Nginx Full"
ufw allow "Nginx HTTP"
ufw allow "Nginx HTTPS"
ufw enable

# copy config files

# remove Canonical service
systemctl disable snapd.service
systemctl disable snapd.socket
systemctl disable snapd.seeded.service
systemctl mask snapd.service
rm -r snap

# essentials
apt update
apt upgrade
apt install tree emacs fish keepassxc -y

# change shell
chsh -s /usr/bin/fish $(which fish) $(whoami)
