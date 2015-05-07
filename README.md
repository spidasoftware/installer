# SPIDAMin Installer

Requirements
------------

1. Ubuntu 14.04+, RHEL 6.5+
2. A Docker Username that you have provided to SPIDA.


Installing SPIDAMin
-------------------

Example install:

```
sudo curl https://raw.githubusercontent.com/spidasoftware/installer/master/install -o install 
sudo chmod +x install 
sudo ./install --serverroot developmentserver.com --filesdir /apps/files --dbpassword password --mongopassword password --tomcatpassword password --userpassword password
sudo rm install
```

Argument            | Description
--------------------|------------------------------------------------------------------------------------------------------------------
--tag               | docker spidamin tag to deploy (defaults to latest)
--apachetag         | docker apache tag to deploy (defaults to latest)
--username          | dockerhub username (will prompt for username if argument is not passed)
--email             | dockerhub email (will prompt for email if argument is not passed)
--password          | dockerhub password (will prompt for email if argument is not passed)
--serverroot        | server root that you will navigate to view the application (ex: min.com)  
--backupdir         | directory for mongo data, postgres data, files and backups (defaults to /apps/spidamin). This has to be backed up.
--dbpassword        | database password
--mongopassword     | mongodb password
--tomcatpassword    | tomcat admin password
--userpassword      | default spidamin user password
--no-spidamin       | don't install spidamin (if databases and SPIDAMin are on different machines)
--no-postgresql     | don't install postgresql (if databases and SPIDAMin are on different machines)
--no-mongodb        | don't install mongodb (if databases and SPIDAMin are on different machines)


Updating SPIDAmin
-----------------
Run the following to update the docker images:

```
sudo curl https://raw.githubusercontent.com/spidasoftware/installer/master/update -o update 
sudo chmod +x update 
sudo ./update 
sudo rm update
```

Argument            | Description
--------------------|--------------------------------------------------------------------------------------------
--username          | dockerhub username (will prompt for username if argument is not passed)
--email             | dockerhub email (will prompt for email if argument is not passed)
--password          | dockerhub password (will prompt for email if argument is not passed)
