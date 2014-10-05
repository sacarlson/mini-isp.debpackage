#! /bin/bash
# this is mod to add link changes to freenet website to switch to normal up mode
source /etc/mini-isp.conf

rm /var/www/freenet.surething.biz/index.php
rm /usr/share/mini-isp/netfail_active.txt
ln -s /var/www/freenet.surething.biz/index.php.netup /var/www/freenet.surething.biz/index.php
/usr/share/mini-isp/masq.sh

