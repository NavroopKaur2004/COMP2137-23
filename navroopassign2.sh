#!/bin/bash
# Hostname changing command 
if [ "$(hostname)" != "autosrv" ]; then
    echo "Host name is $(hostname) and needs to be changed."
    hostnamectl set-hostname autosrv
    echo "Host name has been changed to autosrv."
fi
# network configuration checking
echo "The network settings need to be changed."
echo "The IP address is being changed to 192.168.16.21/24"
ip addr add 192.168.16.21/24 dev "$(ip route | awk '$1 == "default" {default_route = $3} $3 != default_route {print $3}')"
echo "Done."
ip route add default via 192.168.16.1 dev "$(ip route | awk '$1 == "default" {default_route = $3} $3 != default_route {print $3}')"
echo "search home.arpa localdomain" >> /etc/resolv.conf
ip link set "$(ip route | awk '$1 == "default" {default_route = $3} $3 != default_route {print $3}')" up
echo "Network setting have been configured properly."
# software section
echo "Installing required packages."
apt-get install -y openssh-server apache2 squid
echo "Done."
# firewall rules.
echo "Adding firewall rules."
ufw allow 22/tcp
ufw allow 80/tcp
ufw allow 443/tcp
ufw allow 3128/tcp
echo "Done."
# user creation part.
users=("dennis" "aubrey" "captain" "nibbles" "brownie" "scooter" "sandy" "perrier" "cindy" "tiger" "yoda")
for user in "${users[@]}"; do 
    if id "$user" &>/dev/null; then
        echo "User $user already exists."
    else
        useradd -m -s /bin/bash "$user"
        echo "$user has been created."
    fi
    mkdir -p "~/$user/.ssh"
    chown -R "$user:$user" "~/$user/.ssh"
    chmod 700 "~/$user/.ssh"
    if [[ ! -f "~/$user/.ssh/authorized_keys" ]]; then
        touch "~/$user/.ssh/authorized_keys"
    fi
    chmod 600 "~/$user/.ssh/authorized_keys"
done
# change special settings for dennis.
if ! grep -q "$dennis_pub_key" "~/dennis/.ssh/authorized_keys"; then
        echo "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIG4rT3vTt99Ox5kndS4HmgTrKBT8SKzhK4rhGkEVGlCI student@generic-vm" >>"/dennis/.ssh/authorized_keys"
        echo "Added Dennis' public key to dennis's authorized_keys file."
fi
usermod -aG sudo dennis
echo "All users have been created successfully."
echo "All changes have been made."