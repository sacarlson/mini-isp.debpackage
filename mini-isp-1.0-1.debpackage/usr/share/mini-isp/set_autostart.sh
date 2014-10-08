#!/bin/sh
# set or disable mini-isp to start at boot
# to disable start at boot use param stop
# default is to enable start on boot
if [ "$1" = "stop" ]; then
  echo " will disable mini-isp start on boot \n"
  rm -f /etc/cron.d/mini-isp
else
  echo " will disable \n"
  cp /usr/share/mini-isp/mini-isp-cron /etc/cron.d/mini-isp
  echo "mini-isp now set to start at system boot \n"
fi
