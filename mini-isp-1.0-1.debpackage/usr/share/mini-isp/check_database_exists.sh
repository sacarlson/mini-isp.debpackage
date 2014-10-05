#!/bin/sh
# (c) 2014 by Scott Carlson <sacarlson@ipipi.com>
. /etc/mini-isp.conf

RESULT=`mysqlshow --user=root --password=$mysql_pass $mysql_database| grep -v Wildcard | grep -o $mysql_database`
if [ "$RESULT" = "$mysql_database" ]; then
    echo "database $mysql_database already exist so won't create one"
else
  echo "no dababase by that name $mysql_database detected \n"
  Q1="CREATE DATABASE IF NOT EXISTS $mysql_database;"
  Q2="GRANT USAGE ON *.* TO $username@localhost IDENTIFIED BY '$mysql_pass';"
  Q3="GRANT ALL PRIVILEGES ON $mysql_database.* TO $mysql_user@localhost;"
  Q4="FLUSH PRIVILEGES;"
  SQL="${Q1}${Q2}${Q3}${Q4}"

  echo "$SQL \n"  
  mysql -uroot --password=$mysql_pass -e "$SQL"
  echo "mysql database created ok \n"
  #mysql -u $mysql_user --password=$mysql_pass -D $mysql_database < ./freenet3.sql
  mysql -u $mysql_user --password=$mysql_pass -D $mysql_database < /usr/share/mini-isp/mini_isp_cleared.sql
  echo "blank mysql database now installed \n"
fi
exit 0
