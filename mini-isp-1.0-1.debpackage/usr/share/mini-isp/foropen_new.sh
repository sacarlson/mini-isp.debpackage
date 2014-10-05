#!/bin/sh
#
# rc.firewall-iptables
FWVER=0.76
#
#               Initial SIMPLE IP Masquerade test for 2.6 / 2.4 kernels
#               using IPTABLES.  
#
#
#  in scotty's case the eth0 port is on my internet router side
#    and eth1 is on the wifi access point side.
#

echo -e "\n\nLoading simple rc.firewall-iptables version $FWVER..\n"

. /etc/mini-isp.conf

#username=$username
#url=$usr
#internal_interface=$internal_interface
#internal_ip_address=$internal_ip_address
#external_interface=$external_interface
#external_ip_address=$external_ip_address
#router_ip_address=$router_ip_address
#singlenet=$singlenet

#turn off fairnat
#cd /usr/share/mini-isp/fairnat
#/usr/share/mini-isp/fairnat/fairnat-0.80-dhcp.sh stop
#sleep 2

/usr/share/mini-isp/ruby/gen_whitelist.rb
/usr/share/mini-isp/ruby/make_fairnat.config.rb
/usr/share/mini-isp/ruby/set_perm_ip.rb
/usr/share/mini-isp/ruby/make_dhcpd.conf.rb
sudo cp /usr/share/mini-isp/ruby/dhcpd.conf /etc/dhcp/dhcpd.conf
sleep 2
sudo /etc/init.d/dhcp3-server restart
sudo /etc/init.d/isc-dhcp-server restart
# The location of the iptables and kernel module programs
#
#
# ** Please use the "whereis iptables" command to figure out 
# ** where your copy is and change the path below to reflect 
# ** your setup
# 
IPTABLES=/sbin/iptables
DEPMOD=/sbin/depmod
MODPROBE=/sbin/modprobe
WHITELIST=/usr/share/mini-isp/ruby/whitelist.txt

#Setting the EXTERNAL and INTERNAL interfaces for the network
#
#  Each IP Masquerade network needs to have at least one
#  external and one internal network.  The external network
#  is where the natting will occur and the internal network
#  should preferably be addressed with a RFC1918 private address
#  scheme.
#
#  For this example, "eth0" is external and "eth1" is internal"
#
#
EXTIF=$external_interface
INTIF=$internal_interface
INTTAP="tun+"
echo "   External Interface:  $EXTIF"
echo "   Internal Interface:  $INTIF"
echo "   tap  Interface    :  $INTTAP"

#CRITICAL:  Enable IP forwarding since it is disabled by default since
#
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

rm -f /usr/share/mini-isp/netfail_active.txt
rm -f /usr/share/mini-isp/www/freenet.surething.biz/index.php
ln -sf /usr/share/mini-isp/www/freenet.surething.biz/index.php.netup /usr/share/mini-isp/www/freenet.surething.biz/index.php
rm /etc/bind/named.conf.local
ln -sf /etc/bind/named.conf.local.good /etc/bind/named.conf.local
/etc/init.d/bind9 restart


#Clearing any previous configuration
#
#
#
echo "   Clearing any existing rules and setting default policy.. \n"
iptables -X
iptables -F
echo "   Clearing any existing rules and setting default policy flush.. \n"
$IPTABLES --flush                        
$IPTABLES --table nat --flush
$IPTABLES --delete-chain                  
$IPTABLES --table nat --delete-chain

$IPTABLES -P INPUT ACCEPT
$IPTABLES -F INPUT 
$IPTABLES -P OUTPUT ACCEPT
$IPTABLES -F OUTPUT 
$IPTABLES -P FORWARD DROP
$IPTABLES -F FORWARD 
$IPTABLES -t nat -F


echo "   FWD: Allow all connections OUT and all connections  IN"
for x in `grep -v ^# $WHITELIST | awk '{print $1}'`; do
 # added accounting of whithlisted users
  $IPTABLES -I FORWARD -d $x
  $IPTABLES -I FORWARD -s $x 
done
echo "set forward accept on input \n"
if [ "$singlenet" = "true" ]; then
  echo "singlenet set true so will not forward input \n"
else
  echo "singlenet set false so will try enable forward input \n"
  $IPTABLES -A FORWARD -i $EXTIF -j ACCEPT
  $IPTABLES -A FORWARD -i $INTIF -j ACCEPT
  #$IPTABLES -A FORWARD -i $INTTAP -j ACCEPT
fi

# filter only let local network use samba network
echo "filter only let local use samba \n"
$IPTABLES -N SMB-IN
$IPTABLES -A SMB-IN -s 192.168.2.1/24 -j ACCEPT
#$IPTABLES -A SMB-IN -s 192.168.1.1/24 -j ACCEPT
# this opens samba over openvpn but don't thinks that's wise to keep open all the time. bad for video downloads
#$IPTABLES -A SMB-IN -s 10.0.0.0/24 -j ACCEPT
$IPTABLES -A SMB-IN -s 127.0.0.1 -i lo -j ACCEPT
$IPTABLES -A INPUT -p tcp -m multiport --dports 139,445 -j SMB-IN
$IPTABLES -A INPUT -p tcp -m multiport --dports 139,445 -j DROP
$IPTABLES -A INPUT -p udp --dport 137:138 -j SMB-IN
$IPTABLES -A INPUT -p udp --dport 137:138 -j DROP
# end samba local filter

if [ "$singlenet" = "true" ]; then
  echo "singlenet set true so will not enable masquerade \n"
else
  echo "   Enabling SNAT (MASQUERADE) functionality on $EXTIF"
  $IPTABLES  -t nat -A POSTROUTING -o $EXTIF -j MASQUERADE
fi

# reset ipaipac
#/usr/sbin/fetchipac -S
#echo -e "\nrc.firewall-iptables v$FWVER done.\n"
