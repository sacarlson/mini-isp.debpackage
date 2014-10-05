#!/bin/bash
DATE=$(date)
# test if local and wan network is working
# if wan network fails put freenet in fail mode that forwards all trafic to fail web page notice.
# bind9 is also setup on fail to return all lookups to be freenet.surething.biz
# this is set to run every 15 minuets in crontab
# failure must last more that 4 minuets to be considered a real failure
# when the wan network is tested to be working again, network trafic is returned to normal
# and bind9 also reset to normal lookup mode.
source /etc/mini-isp.conf

#username=$username
#url=$usr
#internal_interface=$internal_interface
#internal_ip_address=$internal_ip_address
#external_interface=$external_interface
#external_ip_address=$external_ip_address
#router_ip_address=$router_ip_address
#singlenet=$singlenet

fail_mode_active_path="/usr/share/mini-isp/fail_mode_active.txt"
masq_path="/usr/share/mini-isp/masq.sh"
netfail_switch_fail_path="/usr/share/mini-isp/netfail_switch_fail.sh"
wan_ping="8.8.8.8"
wan_ping2="www.usa.gov"
local_ping=$router_ip_address
ping_log_path="/usr/share/mini-isp/ping.log"

echo "*****************switch_router started for date = $DATE" >> $ping_log_path

if ! ping -c 1 $local_ping
then
  sleep 5
  if ! ping -c 1 $local_ping
  then
    echo "ping local device failed"
    echo "failed local device ping on date = $DATE" >> $ping_log_path
    play /usr/share/mini-isp/ruby/sounds/network_problem.wav
  fi
else
  echo "ping local device ping ok"
  echo "ok local device ping on date = $DATE" >> $ping_log_path
fi
  
for i in {1..5}
do
  if ping -c 1 $wan_ping
  then
    echo "ok ping $wan_ping on date = $DATE" >> $ping_log_path
    echo "ok $wan_ping ping on date = $DATE" 
    if test -f $fail_mode_active_path
    then
      echo "fail mode was set, will clear now"
      echo "fail mode was set, will clear now" >> $ping_log_path
      rm $fail_mode_active_path   
      $masq_path
    fi
    exit -1
  fi
  echo " failed ping $wan_ping on date = $DATE" >> $ping_log_path
  if ping -c 1 $wan_ping2
    then
    echo "ok ping $wan_ping2 on date = $DATE" >> $ping_log_path
    echo "ok $wan_ping2 ping on date = $DATE" 
    if test -f $fail_mode_active_path
    then
      echo "fail mode was set, will clear now"
      echo "fail mode was set, will clear now" >> $ping_log_path
      rm $fail_mode_active_path   
      $masq_path
    fi
    exit -1
  fi
  echo "ping try # $i failed"
  DATE=$(date)
  echo "ping try # $i failed at $DATE" >> $ping_log_path
  sleep 10
done
 
play /usr/share/mini-isp/ruby/sounds/network_problem.wav 
if test -f $fail_mode_active_path
then
  echo "$fail_mode_active already set nothing more needed"
  echo "$fail_mode_active already set nothing more needed" >> $ping_log_path
  exit -1
fi

echo "5th ping failed switching to failnet mode on date = $DATE"
#play /usr/share/mini-isp/Audio/lost_in_space_problem.wav
touch $fail_mode_active_path
#/usr/share/mini-isp/freenet/netfail_switch_fail.sh
$netfail_switch_fail_path
DATE=$(date)
echo "5th wan ping failed switched to failnet mode on date = $DATE" >> $ping_log_path
exit -1
  

echo "*****************test_network completed for date = $DATE" >> $ping_log_path

