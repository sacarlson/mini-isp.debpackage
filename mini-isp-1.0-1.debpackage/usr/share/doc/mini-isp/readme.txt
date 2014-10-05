mini-isp-1.0-1

install instructions
double click in caja the deb file mini-isp-1.0-1.deb and select install button
it may return with failure with dependancys to fix this from term:
sudo apt-get -f install 

or on terminal install with:
cd /path/of/deb/file
sudo gdebi ./mini-isp-1.0-1
sudo apt-get -f install

This will install the needed dependencies for mini-isp.

There will be some questions asked when it installs mysql-server.  be sure the password you enter here matches what you enter for password in mini-isp-1.0-1.

also be sure your computer has about 15G harddisk space for the operating system and for this package and it's dependancies.

phpmyadmin will also ask some questions on install, make sure to select the apache2 checkbox for this one.  It will also ask to configure database for phpmyadmin with dbconfig-common choose <Yes>.

the default settings should work in most cases, just be sure to enter a password.  Also note at this time I didn't add network mask so I think only the 192.168.X.X will work for eth0 and eth1.  I also failed to fix all the zones in dhcp for network failure redirect it won't redirect on all paths unless you use default 192.168.2.250 for eth0.  I may fix this but we don't really needed this since we are up 99.9% of the time now.  It will redirect on .com address so that should be good enuf.

after install make sure you turn off the dhcp service on your ADSL router.  This can normally be done by loging into your box with a browser.  to find out the address of your router you can try:
route -n
this will return a line with flags UG in it that starts with the ip address presently used as your gateway when your 
set to dhcp-client mode.  

I had some problems after install of mini-isp I couldn't access phpmyadmin.  I'm not sure why this happened but was fixed by manualy installing phpmyadmin before installing mini-isp.  I think the problem might be that when I did the apt-get -f install that I didn't select the correct apache2  but maybe the incorect one something lite. I'm still not sure and didn't research it.

The default mysql mini-isp data has a few product contracts in it and also has me scotty as your first customer just setup for test.

for testing make sure the mysql database is working in both masq.sh and in the browser at freenet.surething.biz.  I have some added testing tools I will explain later that are also in the package.  be sure you can access both freenet.surething.biz, freenet.surething.biz/catalog2/  and freenet.surething.biz/catalog2/admin and make sure they all work.  Try some added computers to see they are redirected to freenet.surething.biz before they have working accounts
and after they start accounts and before and after they login see that they get to the internet when we would expect it.



