#!/bin/bash
# (c) 2014 by Scott Carlson <sacarlson@ipipi.com>
#change oscomerce admin username and password to match mini-isp config settings
# if this fails try this password to hash bellow to manualy set password in osc
source /etc/mini-isp.conf
echo "will change osc admin username to $mysql_user"
echo " mysql databas $mysql_database \n"
echo " mysql_pass $mysql_pass \n"
#update_string="UPDATE administrators SET user_name=$mysql_user WHERE user_name=sacarlson;"
#string='SELECT * FROM administrators WHERE id='"1;"
#echo $string "\n"
#update_string="show tables;"
passhash=$(./gen_osc_pass_hash.sh $mysql_pass)
passhashf=$(echo $passhash | tr -d '\r')
echo "osc password hash = $passhashf "
mysql -u $mysql_user --password=$mysql_pass -D $mysql_database <<EOF
UPDATE administrators SET user_name='$mysql_user' WHERE id='1';
UPDATE administrators SET user_password='$passhashf' WHERE id='1';
EOF



