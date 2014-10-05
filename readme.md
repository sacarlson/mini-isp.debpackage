#Mini ISP
Copyright:: Copyright (c) 2012 - 2014 sacarlson

Mini ISP is a group of integrated programs and infrastructure needed to setup a small prepaid WIFI or wired World Wide Internet network service.  It is designed to be used in short to medium term residence like Hotels or resort apartments where residences want a quick method to connect to the Internet from between 1 day to 3 months or longer.  Mini ISP provides captive portal redirected service to unregistered users and enables them to choose and purchase online the desired duration of time to be allowed access to the Internet.  After this time window, world Internet service is automatically discontinued until another contract is purchased.

##License:
 GPLv3 see http://www.gnu.org for details

##Requirments:
* Standard PC computer with at least 256meg ram and minimal 10Gig Hard disk.
* One or more Wifi access points or wired infrastructure for network distribution.
* Linux Mint version 16 - 17, Ubuntu version 13.10 - 14.04 have been tested, maybe others version will also work 

 Mini ISP software was designed to be run on a low power standard PC with as little as 256 meg ram and as little as 10gb available hard disk space partitioned to run on Linux Mint or Ubuntu. Mini ISP also needs to be run on the open source operating systems Linux Mint tested on version 16 - 17 or equivalent Ubuntu version 13.10 - 14.04 server addition or desktop install will work.  You will also need to have at least one connection to the world Internet and either a single or many wifi access points or an infrastructure or wired cat5 local network to provide distribution to your customers. 

##Features:
* Easy debian package installation to install on Linux Mint or Ubuntu and possibly other Debian dirivitives.
* Oscommerce driven store to provide automated customer purchase of service contracts.
* Captive Portal with or without the use of a freeradius server.
* Customer authentication and time/bandwidth usage accounting for each.
* Limited services provided to unregistered customers by iptables redirection.
* Autostart mini-isp system at boot time
* Added optional support to encorporate Coova Chilli captive portal with freeradius authentication, optional.

  See http://freenet.surething.biz to demo a working site.

Note: the debian package version of the original mini-isp features disabled by default but can be customized to include them.  This was done to simplify a basic install with minimal features.

##Instalation:
 Simplified install instructions
 download mini-isp-x.x-x.deb  from https://github.com/sacarlson/mini_isp/mini-isp-1.0.-1.deb .
 then from terminal system you downloaded file to:
 cd /path/of/deb/file
 sudo gdebi mini-isp-1.0-1.deb

 This will install all dependancies needed and ask you the needed questions to complete the install of mini-isp

 I will later add more detail for install if we find it needed.  I would welcome others input to add documentation for install.  Any other feedback is always welcome, good or bad.
