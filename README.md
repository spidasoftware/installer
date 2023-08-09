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
--mongodopts        | mongod options
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

The install script will create a `docker-compose.yml` file in the `/etc/spida` dir.  This is the is the main configuration location for SPIDAMin.  Configuration is set in SPIDAMin by setting environment variables in this docker compose file.  Environment variables that are common among several images are stored in `.docker-common.env`.  The `docker-compose.yml` file will read in that file for the images that share those variables.  This way you only need to change variables in one place instead of multiple places within `docker-compose.yml`.

The following is a list of options for configuration beyond what is done in the install script:

ENV Name: description (default)

* `DATABASE_CONNECTION_STRING`: the jdbc connection string to the database (jdbc:postgresql://postgresql:5432/minmaster)
* `DATABASE_USERNAME`: the username for authentication to the database
* `DATABASE_PASSWORD`: the password for authentication to the database
* `DATABASE_DRIVER`: Class used for JDBC connection (org.postgresql.Driver)
* `DATABASE_VALIDATION_QUERY`: (SELECT 1)
* `DATABASE_BATCH_SIZE`: Max in() size for query (1000)
* `UM_USER_TABLE`: The database table where the users are stored (um_user)
* `UM_USER_DETAILS_TABLE`: the database table where the user details are stored (um_user_details)
* `POSTGRES_USER`: username for postgresql (minmaster)
* `POSTGRES_PASSWORD`: password for postgresql
* `POSTGRES_DATABASE`: the database name inside of postgresql (minmaster)
* `MONGODB_USERNAME`: username for mongodb (minmaster)
* `MONGODB_PASSWORD`: password for mongodb
* `MONGODB_DATABASE`: the database name inside of mongodb (spidadb)
* `MONGODB_HOST`: the host where the mongodb is hosted (mongo)
* `MONGODB_PORT`: the port mongodb is running on (27017)
* `MONGOD_OPTS`: options to pass to mongod
* `TCAT_KEYSTORE_PATH`: the path including filename where the keystore is located (Note: Password is required)
* `TCAT_KEYSTORE_PW`: the required password for the keystore defined in TCAT_KEYSTORE_PATH
* `TOMCAT_PASSWORD`: password for tomcat manager web application
* `TOMCAT_MAX_MEMORY_MB`: max memory for the tomcat image (4096)
* `DEFAULT_PHASE_NAME`: default phase name for event phases (Open)
* `WEBSOCKETS_SUPPORTED`: true or false if websockets should be used for messaging (true)
* `ADMIN_USER_EMAIL`: login for default admin (admin@spidasoftware.com)
* `DAYS_UNTIL_USER_DEACTIVATED`: number of days before disabling inactive users (-1 to disable active check)
* `DATABASE_MAX_ACTIVE_CONNECTIONS`: maximum number of active database connections per application (400)
* `DATABASE_MAX_IDLE_CONNECTIONS`: maximum number of idle database connections per application. Note: This used to DATABASE_MAX_IDLE_CONNECTION if you have a build from before 3/15/17 (400)
* `DATABASE_MIN_EVICTABLE_IDLE_TIME_MILLIS`: The minimum amount of time an object may sit idle in the pool before it is eligible for eviction in ms (60000)
* `DATABASE_TIME_BETWEEN_EVICTION_RUNS_MILLIS`: The number of milliseconds to sleep between runs of the idle connection validation/cleaner thread (60000)
* `DATABASE_MAX_WAIT`: The maximum number of milliseconds that the pool will wait (when there are no available connections) for a connection to be returned before throwing an exception (10000)
* `GEOSERVER_URL`: The geoserver url, this defaults to http://localhost:8080/geoserver which is the geoserver instance distributed with SPIDAMin.  Only set this if you host geoserver and don't use the SPIDAMin instance.
* `USERS_SERVICE_MAX_CONNECTIONS`: The maximum number of http connections for the users service(400)
* `DEFAULT_DB_USER_ID`: The default user id to use in SPIDADB when pushing to DB and the user is not logged in(null)
* `DEFAULT_DB_USER_EMAIL`: The default user email to use in SPIDADB when pushing to DB and the user is not logged in(null)
* `MAX_HTTP_CONNECTIONS`: Maxinum number of http connections from Min(400)
* `MAX_HTTP_CONNECTIONS_PER_HOST`: Maxinum number of http connections from Min per host(400)
SSL
---

If you are using your own ssl certificates you will need to place the needed files with the correct names in the `apache_ssl` folder that is located in your config dir. 

1. `apache.pem`: (required) primary certificate
2. `server.key`: (required) key to certificate
3. `intermediate.pem`: (optional) intermediate certificate
