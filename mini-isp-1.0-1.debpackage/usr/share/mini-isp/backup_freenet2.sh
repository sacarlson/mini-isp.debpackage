#! /bin/bash
#make backup of freenet install package
#must be run with sudo

mysqldump -usacarlson -ppassword --all-databases > mysql_all.sql
#mysqldump -usacarlson -ppassword freenet3 > freenet3.sql

