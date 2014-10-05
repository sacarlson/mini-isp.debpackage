#! /bin/bash
# forward all port 80 trafic to freenet web page except addresses in whiteslist.txt file
# eth0 is on internet router side, eth1 is on the wifi access point side
# eth0 is set to 192.168.2.240 on oldbox
# eth1 is set to 192.168.1.240 on oldbox
# this one modified to leave raj ip open with no login.
# must modify this line to match what we assign to raj
#added ip address  for quick shut down of single custom users.
# see /etc/dhcp3/dhcpd.conf for details
# may also require macchanger.
#  modified to add link to send freenet site to fail mode and disable whitelist so all trafic is sent to freenet on fail
source /etc/mini-isp.conf

rm /var/www/freenet.surething.biz/index.php
touch /usr/share/mini-isp/netfail_active.txt
ln -s /var/www/freenet.surething.biz/index.php.netfailed /var/www/freenet.surething.biz/index.php


EXTIF=$external_interface
INTIF=$internal_interface
INTTAP="tun+"
echo "   External Interface router side:  $EXTIF"
echo "   Internal Interface access point side:  $INTIF"
echo "   Internal tap Interface for optional vpn:  $INTTAP"

EXTIP=$external_ip_address
INTIP=$internal_ip_address
ROUTERIP=$router_ip_address
vpn_enable="false"

#vpn_enable="true"
vpn_enable="false"
if [ $vpn_enable = 'true' ]; then
  echo "vpn enabled"
  #ifconfig eth0:2 down
  #openvpn didn't start correct at boot so restart here
  #note vpn uses 192.168.1.112 network so must not have eth0 with that network here
  /home/sacarlson/vpn/tls-server_freenet.sh
  # add gateway to network for openvpn client
  sleep 1
  route add -net 192.168.1.0 netmask 255.255.255.0 gw 10.0.0.2
  sleep 6
else
  echo "vpn disabled"
  ifconfig tun0 down
  sleep 1
  if [$singlenet = 'false' ]; then
    ifconfig $EXTIF down
    ifconfig $EXTIF $EXTIP
  fi
  ifconfig $INTIF down
  sleep 2
  ifconfig $INTIF $INTIP
  sudo route del default
  sudo route add default gw $ROUTERIP
fi

IPTABLES=/sbin/iptables
DEPMOD=/sbin/depmod
MODPROBE=/sbin/modprobe
BLACKLIST=/usr/share/mini-isp/blacklist.txt
WHITELIST=/usr/share/mini-isp/whitelist.txt
#
## Specify ports you wish to use.

#ALLOWED="22 53 80 443 465 587 993 999:65000"
ALLOWED="21:65000"

#Setting the EXTERNAL and INTERNAL interfaces for the network
#EXTIF = BILLION ROUTER SIDE
#INTIF = DLINK ACCESSPOINT SIDE

echo "   External Interface router side:  $EXTIF"
echo "   Internal Interface access point side:  $INTIF"
echo "   Internal Interface:  $INTIF2"
echo "   Internal tap Interface:  $INTTAP"
echo "   External IP:  $EXTIP"

#                             to
#                       FORWARD_IPV4=true
#
echo "   Enabling forwarding.."
echo "1" > /proc/sys/net/ipv4/ip_forward


# Dynamic IP users:
#
#   If you get your IP address dynamically from SLIP, PPP, or DHCP, 
#   enable this following option.  This enables dynamic-address hacking
#   which makes the life with Diald and similar programs much easier.
#
echo "   Enabling DynamicAddr.."
echo "1" > /proc/sys/net/ipv4/ip_dynaddr


# Enable simple IP forwarding and Masquerading
#
#  NOTE:  In IPTABLES speak, IP Masquerading is a form of SourceNAT or SNAT.
#
#
echo "   Clearing any existing rules and setting default policy.."
$IPTABLES --flush                        
$IPTABLES --table nat --flush
$IPTABLES --delete-chain                  
$IPTABLES --table nat --delete-chain
# above added later
$IPTABLES -P INPUT ACCEPT
$IPTABLES -F INPUT 
$IPTABLES -P OUTPUT ACCEPT
$IPTABLES -F OUTPUT 
$IPTABLES -P FORWARD DROP
$IPTABLES -F FORWARD 
$IPTABLES -t nat -F


#
## Blacklist
#

for x in `grep -v ^# $BLACKLIST | awk '{print $1}'`; do
    echo "Denying $x..."
    $IPTABLES -A INPUT -t filter -s $x -j DROP
	$IPTABLES -A INPUT -t filter -d $x -j DROP
	$IPTABLES -A FORWARD -d $x -j DROP
	$IPTABLES -A FORWARD -s $x -j DROP
done

echo 'Allowing Localhost'
#Allow localhost.
$IPTABLES -A INPUT -t filter -s 127.0.0.1 -j ACCEPT

# add filter to drop all port 21 and 22 from eth0 (world internet access)  to prevent attempted rsh breakin
# change of plan just allow all to bigboy and restrict prots 21 and 22... to all others see port allow list to change
$IPTABLES -A INPUT -t filter -d $EXTIP -j ACCEPT
$IPTABLES -A INPUT -t filter -s $EXTIP -j ACCEPT
$IPTABLES -A INPUT -t filter -s 10.0.0.1 -j ACCEPT
$IPTABLES -A INPUT -t filter -d 10.0.0.1 -j ACCEPT
#
## Permitted Ports
#allow dns port 53
$IPTABLES -A INPUT -t filter -p udp --sport 53 -j ACCEPT
#allow ping icmp port
$IPTABLES -A INPUT -p icmp  -j ACCEPT 

for port in $ALLOWED; do
        echo "Accepting port TCP $port..."
        $IPTABLES -A INPUT -t filter -p tcp --dport $port -j ACCEPT
done

for port in $ALLOWED; do
        echo "Accepting port UDP $port..."
        $IPTABLES -A INPUT -t filter -p udp --dport $port -j ACCEPT
done


# filter only let local network use samba network
$IPTABLES -N SMB-IN
$IPTABLES -A SMB-IN -s 192.168.2.1/24 -j ACCEPT
$IPTABLES -A SMB-IN -s 192.168.1.1/24 -j ACCEPT
# this opens samba over openvpn but only good if you need it. not good for video downloads
#$IPTABLES -A SMB-IN -s 10.0.0.0/24 -j ACCEPT
$IPTABLES -A SMB-IN -s 127.0.0.1 -i lo -j ACCEPT

$IPTABLES -I INPUT -p tcp -m multiport --dports 139,445 -j DROP
$IPTABLES -I INPUT -p udp --dport 137:138 -j DROP
$IPTABLES -I INPUT -p udp --dport 137:138 -j SMB-IN
$IPTABLES -I INPUT -p tcp -m multiport --dports 139,445 -j SMB-IN
# end samba local filter

$IPTABLES -A INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT
$IPTABLES -A INPUT -p udp -j DROP
$IPTABLES -A INPUT -p tcp --syn -j DROP


echo "   FWD: Allow all connections OUT and all connections  IN"
$IPTABLES -A FORWARD -i $EXTIF -j ACCEPT
$IPTABLES -A FORWARD -i $INTIF -j ACCEPT
$IPTABLES -A FORWARD -i $INTIF2 -j ACCEPT
$IPTABLES -A FORWARD -i $INTTAP -j ACCEPT

#$IPTABLES -t nat -A POSTROUTING -o $EXTIF -j SNAT --to $EXTIP

echo "   Enabling SNAT (MASQUERADE) functionality on $EXTIF"
$IPTABLES -t nat -A POSTROUTING -o $EXTIF -j MASQUERADE

echo -e "\nrc.firewall-iptables v$FWVER done.\n"


#WHITELIST=/home/sacarlson/whitelist.txt
#
## Whitelist
#
$IPTABLES -t nat -A PREROUTING -d $EXTIP -j RETURN
#$IPTABLES -t nat -A PREROUTING -d 192.168.1.250 -j RETURN

# added for openvpn
$IPTABLES -t nat -A PREROUTING -d 192.168.1.0/24 -j RETURN
$IPTABLES -t nat -A PREROUTING -s 10.0.0.0/24 -j RETURN
#$IPTABLES -A FORWARD -i tun0 -o eth0 -s 10.0.0.0/24  -j ACCEPT

# added accounting
$IPTABLES -I FORWARD -p tcp --sport 443
$IPTABLES -I FORWARD -p tcp --dport 443
$IPTABLES -I FORWARD -p tcp --sport 80
$IPTABLES -I FORWARD -p tcp --dport 80
# account for all udp activity above port 1023
$IPTABLES -I FORWARD -p udp --sport 1024:
$IPTABLES -I FORWARD -p udp --dport 1024:

#  disable whitelist for netfail mode
#for x in `grep -v ^# $WHITELIST | awk '{print $1}'`; do
 # added accounting of whithlisted users
#  $IPTABLES -I FORWARD -d $x
#  $IPTABLES -I FORWARD -s $x 
#  $IPTABLES -t nat -A PREROUTING -s $x -j RETURN
#done

$IPTABLES -t nat -A PREROUTING -p tcp --dport 53 -j RETURN
$IPTABLES -t nat -A PREROUTING -p udp --dport 53 -j RETURN
$IPTABLES -t nat -A PREROUTING -p udp --sport 53 -j RETURN
$IPTABLES -t nat -A PREROUTING -p tcp --sport 53 -j RETURN
$IPTABLES -t nat -A PREROUTING -p tcp  -j DNAT --to-destination $EXTIP
$IPTABLES -t nat -A PREROUTING -p udp  -j DNAT --to-destination $EXTIP



echo "end forfire.sh"
