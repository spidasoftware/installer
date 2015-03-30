# installer

Installation Requirements
----------

1. Ubuntu 14.04+, RHEL 6.5+
2. A Docker Username that you have provided to SPIDA.


Default Installation
-------------------

A complete installation is completed by running the following command on the server

`sudo curl -o install https://raw.githubusercontent.com/spidasoftware/installer/master/install && sudo chmod +x install && sudo ./install && sudo rm install`

Install Script Options
------------------------------
* -tag              docker spidamin tag to deploy (defaults to latest)
* -username         dockerhub username (will prompt for username if argument is not passed)
* -email            dockerhub email (will prompt for email if argument is not passed)
* -serverroot       server root that you will navigate to view the application (ex: min.com or min.com:8443)  
* -filesdir         files directory that spidamin files will be stored in (defaults to /apps/spidamin/files)
* -dbpassword       database password
* -mongopassword    mongodb password
* -tomcatpassword   tomcat admin password
* -userpassword     default spidamin user password
* --no-spidamin     don't install spidamin
* --no-postgresql   don't install postgresql
* --no-mongodb      don't install mongodb

Example Development Machine Install Command:
`sudo curl -o install https://raw.githubusercontent.com/spidasoftware/installer/master/install && sudo chmod +x install && sudo ./install -serverroot developmentserver.com:8443 -filesdir /apps/files -dbpassword password -mongopassword password -tomcatpassword password -userpassword password && sudo rm install`

Update Script
------------
To update the SPIDAMin deployment with the newest docker images:
`sudo curl -o update https://raw.githubusercontent.com/spidasoftware/installer/master/update && sudo chmod +x update && sudo ./update && sudo rm update`
