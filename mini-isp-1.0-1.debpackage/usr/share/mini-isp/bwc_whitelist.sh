#!/bin/bash
# bandwidth control that finds active hosts on system network
# and provides each with an equal share of download and upload bandwidth
# this is writen to share a 13mbit ISP with from 2 - 20 people
# you can squease more people in if some aren't too greedy using bw 
#  Options also available to customize static IP users
#  this is tested on  ubuntu/mint version 14,16
#  tc uses the following units when passed as a parameter.
#  kbps: Kilobytes per second 
#  mbps: Megabytes per second
#  kbit: Kilobits per second
#  mbit: Megabits per second
#  bps: Bytes per second 
#       Amounts of data can be specified in:
#       kb or k: Kilobytes  (this didn't work in ubuntu)
#       mb or m: Megabytes
#       mbit: Megabits (this works)
#       kbit: Kilobits  (this works)
#  To get the byte figure from bits, divide the number by 8 bit
#
#  Edited by Scott Carlson  10/31/13    Copywrite  GPL
#  sacarlson@ipipi.com
source /etc/mini-isp.conf

# Name of the traffic control command and other bin files.
TC="/sbin/tc"
IPTABLES="/sbin/iptables"
ARP="arp -n"
GREP="/bin/grep"
IFCONFIG="/sbin/ifconfig"
SED="/bin/sed"
WHITELIST=/usr/share/mini-isp/ruby/whitelist.txt
insmod sch_sfq >&- 2>&-
insmod cls_fw >&- 2>&-
insmod sch_hfsc >&- 2>&-
insmod sch_htb >&- 2>&-

# ignore IP list, Ignore these ip addreses in bandwidth control, space delimited
# if an IP address is to be customized it must be ignored here first, also gateway to Internet is ignored here
#ip_ignore_list="$internal_ip_address  192.168.2.186"
#ip_ignore_list="192.168.2.252 192.168.2.253 192.168.2.186 192.168.2.192"

#manualy add to list, to be added to the active list even if not seen on local network yet
#ip_add_list="192.168.2.192 192.168.2.209 192.168.2.207 192.168.2.202"
#ip_add_list="192.168.2.209 192.168.2.207"


# the address base of the network we plan to control bandwidth
# this way we ignore all trafic connected on another ethx or other nic device now done auto bellow
#base_ip_net="192.168.2.1"

# The network interface we're planning on limiting download bandwidth nic on local lan side to user.
IF=$internal_interface             # Interface

# The network interface were planning on limiting bandwidth from user to Internet (upload) nic that points to WAN network.
IFUP=$external_interface

#CEILTOP is the bandwidth cealing for the top parent of all other classes, it should be about 20% less than max bw 
# provided by isp provider.
# I pay for 13mbit from my True ISP but only get about 10mbit at peak hours so 8mbit should be good here 
CEILTOP="9mbit"

# Default Download limit  this is the garenteed bandwidth service for whitelisted users 
# I find 2mbit is about minimal for most customers that want to stream youtube.com video
# not sure why but with dnld=2mb, ceil=8mb I get measurements of speed test ast 6.6mb witch is good as it's half
#DNLD="400kbit"          # DOWNLOAD Limit
DNLD="2mbit" 

#CEIL is ceiling bw limit for the maximum bandwidth that will be provided whitelisted users
CEIL="7mbit"

# Upload Limit
UPLD="200kbit"

# Upload ceiling
UPCEIL="800kbit"

# ceiling non members for all other ip's that are not on the whitelist
# with this set I now read non member at 1.9mbit/s on bw tested at http://www.speedtest.net/
CEILNM="2mbit"

#****************************************** end config values *******************************

DEV_LAN_IP=`$IFCONFIG $IF | \
            $GREP 'inet addr' | \
            $SED -e s/^.*inet\ addr://g -e s/\ .*$//g`

DEV_LAN_SUBNET=`echo $DEV_LAN_IP | $SED -e s/\.[0-9]*$//g`
base_ip_net="$DEV_LAN_SUBNET.1"
echo "dev_lan_ip $DEV_LAN_IP"
echo "subnet $DEV_LAN_SUBNET"
echo "base_ip_net $base_ip_net"

HNDL="1"
if [ "$IF" != "$IFUP" ]
then
  HNDL="2"     
fi

echo "HNDL = $HNDL"

# Filter options for limiting the intended interface.
#U32="$TC filter add dev $IF protocol ip parent 1:1 prio 1 u32"

add_class() {
  # create an htb with sfq class for an ip
  # enter function with IP , DNLD , CEIL  to desired values 
  echo "start add_class"
  echo $IP
  # DNLD rate is the garanteed rate to the user or minimum rate expected
  echo "download rate $DNLD"
  # ceiling rate is the maximum bw that a user will be allowed to barrow if available 
  echo "download ceiling $CEIL"
  class=$(echo $IP | cut -d"." -f4)  
  class_up=$(($class + 1000))
  echo $class
  echo "class_up = $class_up"
  
  

  #download control
  $TC class add dev $IF parent 1:2 classid 1:$class htb rate $DNLD ceil $CEIL prio 2
  $TC qdisc add dev $IF parent 1:$class handle $class: sfq perturb 10
  $TC filter add dev $IF parent 1:0 protocol ip prio 2 handle $class fw classid 1:$class
  $IPTABLES -t mangle -A POSTROUTING -o $IF -d $IP -j MARK --set-mark $class
  $IPTABLES -t mangle -A POSTROUTING -o $IF -d $IP -j RETURN
  
  #up load control
  $TC class add dev $IFUP parent $HNDL:2 classid $HNDL:$class_up htb rate $UPLD ceil $UPCEIL prio 2
  $TC qdisc add dev $IFUP parent $HNDL:$class_up handle $class_up: sfq perturb 10
  $TC filter add dev $IFUP parent $HNDL:0 protocol ip prio 2 handle $class_up fw classid $HNDL:$class_up
  $IPTABLES -t mangle -A POSTROUTING -o $IFUP -s $IP -j MARK --set-mark $class_up
  $IPTABLES -t mangle -A POSTROUTING -o $IFUP -s $IP -j RETURN

  # The first line creates the root qdisc, and the next two lines
  # create two child qdisc that are to be used to shape download 
  # and upload bandwidth.
  #
  # The 5th and 6th line creates the filter to match the interface.
  # The 'dst' IP address is used to limit download speed, and the 
  # 'src' IP address is used to limit upload speed.

}


start() {

  # We'll use Hierarchical Token Bucket (HTB) to shape bandwidth.
  # For detailed configuration options, please consult Linux man
  # page.
  # create a list of all active IP seen in arp logs
  # also aded  Stochastic Fairness Queueing (SFQ) and priority for ssh and some ack syn rst packets
  # we now control both upload and download bandwidth of each active ip seen plus
  # the IP's that are added in the manual list
  
  
  #download control
  echo "start download setup"
  $TC qdisc add dev $IF root handle 1: htb default 15
  echo "first handle create"
  $TC class add dev $IF parent 1:0 classid 1:2 htb rate $CEILTOP ceil $CEILTOP
  $TC class add dev $IF parent 1:2 classid 1:10 htb rate 100kbit ceil 150kbit prio 1
  $TC class add dev $IF parent 1:2 classid 1:15 htb rate 1000kbit ceil $CEILNM prio 3
  $TC class add dev $IF parent 1:2 classid 1:80 htb rate 10kbit ceil 20kbit prio 4
  $TC qdisc add dev $IF parent 1:80 handle 80: sfq perturb 10

  $TC filter add dev $IF parent 1:0 protocol ip prio 1 handle 1 fw classid 1:10
  $TC filter add dev $IF parent 1:0 protocol ip prio 3 handle 15 fw classid 1:15  
  $TC filter add dev $IF parent 1:0 protocol ip prio 4 handle 80 fw classid 1:80

  # upload control 
  echo "start upload setup"
  if [ "$IF" != "$IFUP" ]
  then
    echo "added handle 2 qdisc for dual nics"
    $TC qdisc add dev $IFUP root handle 2: htb default 25    
  fi
  $TC class add dev $IFUP parent $HNDL:0 classid $HNDL:2 htb rate $UPCEIL ceil $UPCEIL

  # at this time prio 1 and prio 3 not used on upload, maybe later
  $TC class add dev $IFUP parent $HNDL:2 classid $HNDL:20 htb rate 100kbit ceil 150kbit prio 1
  $TC class add dev $IFUP parent $HNDL:2 classid $HNDL:25 htb rate 100kbit ceil $UPCEIL prio 3

  $TC filter add dev $IFUP parent $HNDL:0 protocol ip prio 1 handle 20 fw classid $HNDL:20
  $TC filter add dev $IFUP parent $HNDL:0 protocol ip prio 3 handle 25 fw classid $HNDL:25


  #flags ack syn rst and ping packets prio 1   
  $IPTABLES -t mangle -I PREROUTING -p tcp -m tcp --tcp-flags SYN,RST,ACK SYN -j RETURN
  #$IPTABLES -t mangle -I PREROUTING -p tcp -m tcp --tcp-flags SYN,RST,ACK SYN -j MARK --set-mark 1
  $IPTABLES -t mangle -I PREROUTING -p tcp -m tcp --tcp-flags SYN,RST,ACK SYN -j TOS --set-tos Minimize-Delay
  #$IPTABLES -t mangle -A PREROUTING -p icmp -j MARK --set-mark 1
  $IPTABLES -t mangle -A PREROUTING -p icmp -j TOS --set-tos Minimize-Delay
  $IPTABLES -t mangle -A PREROUTING -p icmp -j RETURN
 
  # ssh service provide prio 1 
  $IPTABLES -t mangle -A PREROUTING -p tcp -m tcp --dport 22 -j TOS --set-tos Minimize-Delay
  $IPTABLES -t mangle -A PREROUTING -p tcp -m tcp --dport 22 -j RETURN
  

  # apache service provide prio 3 30kbit to reduce none local http robot trafic from killing my local trafic
  # set mark 80 if source port is 80 and it's destination is not within the local network
  $IPTABLES -t mangle -A POSTROUTING  -o $IF -p tcp -m tcp --sport 80 ! -d "$base_ip_net/24" -j MARK --set-mark 80
  $IPTABLES -t mangle -A POSTROUTING  -o $IF -p tcp -m tcp --sport 80 ! -d "$base_ip_net/24" -j RETURN

  #set all whitelisted IP to default DNLD and CEIL limits
  
  for IP in `grep -v ^# $WHITELIST | awk '{print $1}'`; do   
     echo $IP
     add_class   
  done
    
  
  # custom setups for 192.168.2.x
  IP="192.168.2.220"
  #  Download limit (in kbits or mbits)
  DNLD="500kbit"          # DOWNLOAD Limit
  CEIL="4000kbit"  
  # Upload Limit
  UPLD="100kbit"
  # Upload ceiling
  UPCEIL="400kbit"
  #add_class

 

  # provide other IP address not seen when run with limited prio 3 service (non members?)
  # they will all share from a single block of bandwidth that is 200kb download with 8mb cieling
  $IPTABLES -t mangle -A POSTROUTING -d "$base_ip_net/255.255.255.0" -j MARK --set-mark 15
  $IPTABLES -t mangle -A POSTROUTING -d "$base_ip_net/255.255.255.0"  -j RETURN
  $IPTABLES -t mangle -A POSTROUTING -s "$base_ip_net/255.255.255.0" -j MARK --set-mark 25
  $IPTABLES -t mangle -A POSTROUTING -s "$base_ip_net/255.255.255.0"  -j RETURN

}

stop() {

# Stop the bandwidth shaping.
    $TC qdisc del dev $IF root
    $TC qdisc del dev $IFUP root
    $IPTABLES -F -t mangle
    $IPTABLES -t mangle -X
}

restart() {

# Self-explanatory.
    stop
    sleep 1
    start

}

show() {

# Display status of traffic control status.
    $TC -s qdisc ls dev $IF
    $TC -s -d class show dev $IF
    $TC -s filter show dev $IF

    $TC -s qdisc ls dev $IFUP
    $TC -s -d class show dev $IFUP
    $TC -s filter show dev $IFUP

    $IPTABLES -t mangle -L -n -v

}

case "$1" in

  start)

    echo -n "Starting bandwidth shaping: "
    start
    echo "done"
    ;;

  stop)

    echo -n "Stopping bandwidth shaping: "
    stop
    echo "done"
    ;;

  restart)

    echo -n "Restarting bandwidth shaping: "
    restart
    echo "done"
    ;;

  show)

    echo "Bandwidth shaping status for $IF:"
    show
    echo ""
    ;;

  *)

    pwd=$(pwd)
    echo "Usage: bwc {start|stop|restart|show}"
    ;;

esac

exit 0
