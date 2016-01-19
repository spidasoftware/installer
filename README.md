# SPIDAMin Installer

Requirements
------------

1. Ubuntu 14.04+, RHEL 7.0+
2. A Docker Username that you have provided to SPIDA.


Installing SPIDAMin
-------------------

Example install:

```
sudo curl https://raw.githubusercontent.com/spidasoftware/installer/master/install -o install 
sudo chmod +x install 
sudo ./install --serverroot developmentserver.com --backupdir /apps/spidamin \\
  --dbpassword password --mongopassword password --tomcatpassword password --userpassword password
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
--backupdir         | directory for mongo data, postgres data, files and backups (defaults to /var/spida). This has to be backed up.
--configdir         | directory for configuration files (defaults to /etc/spida)
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

Docker Compose
--------------

The install script will create a docker-compose.yml file in the `/etc/spida` dir.  This is the is the main configuration location for SPIDAMin.  Configuration is set in SPIDAMin by setting environment variables in this docker compose file.  The following is a list of options for configuration beyond that that is done in the install script:

ENV Name: description (default)

* `DATABASE_CONNECTION_STRING`: the jdbc connection string to the database (jdbc:postgresql://postgresql:5432/minmaster)
* `DATABASE_USERNAME`: the username for authentication to the database
* `DATABASE_PASSWORD`: the password for authentication to the database
* `DATABASE_DRIVER`: Class used for JDBC connection (org.postgresql.Driver)
* `DATABASE_VALIDATION_QUERY`: (SELECT 1)
* `UM_USER_TABLE`: The database table where the users are stored (um_user)
* `UM_USER_DETAILS_TABLE`: the database table where the user details are stored (um_user_details)
* `MONGODB_DATABASE`: the database name inside of mongodb (spidadb)
* `MONGODB_HOST`: the host where the mongodb is hosted (mongo)
* `MONGODB_PORT`: the port mongodb is running on (27017)
* `MONGODB_USERNAME`: username for mongodb
* `MONGODB_PASSWORD`: password for mongodb
* `TOMCAT_MAX_MEMORY_MB`: max memory for the tomcat image (4096)
* `ADMIN_USER_EMAIL`: login for default admin (admin@spidasoftware.com)

