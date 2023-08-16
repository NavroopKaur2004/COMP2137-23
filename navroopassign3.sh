#!/bin/bash

# First step will be to make functions for work         
# these functions help keep script clean
# also help me do more productivity
# First function is to check errors for commands executed 


error_check() {
    if [ $? -ne 0 ]; then
        echo "ERROR: $1"
        exit 1
    fi
}



# Second function is related to first script.
# This will be used to setup my first target
# name this script 1

script1() {
    server1ip="172.16.1.10"
    
    # Set hostname to loghost
    # hostname ctl command for this
    # also use ssh for all commands since this will be attacking remotely.
    ssh remoteadmin@$server1ip "hostnamectl set-hostname loghost"
    error_check "Hostname server1 is being changed"

    # Configure IP address
    ssh remoteadmin@$server1ip "ip addr add 192.168.1.3/24 dev eth0"
    error_check "IP address on server1 will be changed"

    # Add entry to /etc/hosts
    ssh remoteadmin@$server1ip "echo '192.168.1.4 webhost' | tee -a /etc/hosts"
    error_check "webhost entry to /etc/hosts on server1"

    # Install and configure UFW
    ssh remoteadmin@$server1ip "dpkg -l | grep -E '^ii' | grep -q ufw || apt-get install -y ufw"
    ssh remoteadmin@$server1ip "ufw allow from 172.16.1.0/24 to any port 514/udp"
    error_check "UFW on server1"

    # Configure rsyslog
    ssh remoteadmin@$server1ip "sed -i '/imudp/s/^#//g' /etc/rsyslog.conf"
    ssh remoteadmin@$server1ip "sed -i '/UDPServerRun/s/^#//g' /etc/rsyslog.conf"
    ssh remoteadmin@$server1ip "systemctl restart rsyslog"
    error_check "rsyslog on server1"
}
# now it is time for the second server function.
# Configuration of server2 function named script2
script2() {
    server2ip="172.16.1.11"
    
    # Set hostname to webhost
    ssh remoteadmin@$server2ip "hostnamectl set-hostname webhost"
    error_check "hostname on server2"

    # Configure IP address
    ssh remoteadmin@$server2ip "ip addr add 192.168.1.4/24 dev eth0"
    error_check "IP address on server2"

    # Add entry to /etc/hosts
    ssh remoteadmin@$server2ip "echo '192.168.1.3 loghost' | tee -a /etc/hosts"
    error_check "loghost entry to /etc/hosts on server2"

    # Install and configure UFW
    ssh remoteadmin@$server2ip "dpkg -l | grep -E '^ii' | grep -q ufw || apt-get install -y ufw"
    ssh remoteadmin@$server2ip "ufw allow 80/tcp"
    error_check "UFW on server2"

    # Install Apache2
    ssh remoteadmin@$server2ip "apt-get install -y apache2"
    error_check "Apache2 on server2"

    # Configure rsyslog
    ssh remoteadmin@$server2ip "echo '*.* @loghost' | tee -a /etc/rsyslog.conf"
    ssh remoteadmin@$server2ip "systemctl restart rsyslog"
    error_check "rsyslog on server2"
}
# next function is for nms updates.
#i.e. new names and ip addresses.
# Update NMS Configuration
update_nms_config() {
    echo "192.168.1.3 loghost" | sudo tee -a /etc/hosts
    echo "192.168.1.4 webhost" | sudo tee -a /etc/hosts
}
# next function is to verify
# Verify Apache configuration
verify_apache() {
    curl -s http://webhost | grep -q "Apache2 Ubuntu Default Page"
    if [ $? -eq 0 ]; then
        echo "SUCCESS"
    else
        echo "ERROR"
    fi
}

# Verify syslog configuration
verify_syslog() {
    ssh remoteadmin@loghost "grep webhost /var/log/syslog" | grep -q "webhost"
    if [ $? -eq 0 ]; then
        echo "SUCCESS"
    else
        echo "ERROR"
    fi
}

# Main Script     
# now i will run all the functions one by one.
# Configure server1
script1

# Configure server2
script2

# Update NMS Configuration
update_nms_config

# Verify Apache configuration
verify_apache

# Verify syslog configuration
verify_syslog

# Final Message for the user before end of the script.
echo "Configuration update succeeded!"
