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
sudo ./install -serverroot developmentserver.com -filesdir /apps/files -dbpassword password -mongopassword password -tomcatpassword password -userpassword password
sudo rm install
```

Argument           | Description
-------------------|--------------------------------------------------------------------------------------------
-tag               | docker spidamin tag to deploy (defaults to latest)
-apachetag         | docker apache tag to deploy (defaults to latest)
-username          | dockerhub username (will prompt for username if argument is not passed)
-email             | dockerhub email (will prompt for email if argument is not passed)
-serverroot        | server root that you will navigate to view the application (ex: min.com)  
-filesdir          | files directory that spidamin files will be stored in (defaults to /apps/spidamin/files)
-dbpassword        | database password
-mongopassword     | mongodb password
-tomcatpassword    | tomcat admin password
-userpassword      | default spidamin user password
-mongobackupdir    | directory that mongodb backups will be stored (defaults to /apps/spidamin/backups/mongodb)
-postgresbackupdir | directory that mongodb backups will be stored (defaults to /apps/spidamin/backups/postgres)
-mongodatadir      | mongodb data directory (defaults to not mounted)
--no-spidamin      | don't install spidamin (if databases and min are on differnt machines)
--no-postgresql    | don't install postgresql (if databases and min are on differnt machines)
--no-mongodb       | don't install mongodb (if databases and min are on differnt machines)


Updating SPIDAmin
-----------------
Run the following to update the docker images:

```
sudo curl https://raw.githubusercontent.com/spidasoftware/installer/master/update -o update 
sudo chmod +x update 
sudo ./update 
sudo rm update
```
