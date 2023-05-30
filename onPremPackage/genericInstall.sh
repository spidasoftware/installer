#!/bin/bash

# Source Company File
source company.conf

####################################################################################
#
# Vars
#
####################################################################################
serverRoot=$(hostname -f)
# Docker Vars
dockerUsername=""
dockerPassword=""
dockerStart=true

# SQL Vars
databasePassword=""
databaseUsername=""
databaseConnStr=""
databaseDriver=""

# Mongo Vars
mongoURI=""
mongoHost=""
mongoPort=""
mongoUser=""
mongoDatabase=""
mongoPassword=""
mongodOpts=""

# Tomcat Vars
tomcatAdminPassword=""
tomcatMemory=""

# SPIDA Studio Vars
adminUsername=""
defaultUserPassword=""
defaultUserApiToken=""
disableCountdown=false
interchangeCookieName=""
interchangeCookieSecret=""

# Application E-mail Vars
alertEmail=""
emailHost=""
emailPort=""

# SAML Vars
samlPassword=""
samlAlias=""
samlDir=""

# Add Container to Compose Vars
spidaMin=true
postgresql=true
mongo=true

# Environment Descriptors
hasDockerConfig=false

# Application Installation Conf
backupDir="/apps/spidamin"
appconfigDir="${backupDir}/spida"

# Container Tags
tag="latest"
postgresqlTag="latest"
mongodbTag="latest"
redisTag="latest"
apacheTag="latest"
MIN_TAG_PASSED=false
POSTGRESQL_TAG_PASSED=false
MONGODB_TAG_PASSED=false
REDIS_TAG_PASSED=false
APACHE_TAG_PASSED=false

# Apache Vars
defaultApacheApp=""
sendgridApiKey=""
apache=true

####################################################################################
#
# Parses Args
#
####################################################################################
function parseCommandLineArguments() {
  while [ $# -gt 0 ]
  do
      case "$1" in
          --tag) tag="$2"; MIN_TAG_PASSED=true; shift;;
          --postgresql-tag)  postgresqlTag="$2"; POSTGRESQL_TAG_PASSED=true; shift;;
          --mongodb-tag)  mongodbTag="$2"; MONGODB_TAG_PASSED=true; shift;;
          --redis-tag)  redisTag="$2"; REDIS_TAG_PASSED=true; shift;;
          --apache-tag)  apacheTag="$2"; APACHE_TAG_PASSED=true; shift;;
          --server-root)  serverRoot="$2"; shift;;
          --docker-username)  dockerUsername="$2"; shift;;
          --docker-password)  dockerPassword="$2"; shift;;
          --backupdir)  backupDir="$2"; shift;;
          --db-conn-str)  databaseConnStr="$2"; shift;;
          --db-driver)  databaseDriver="$2"; shift;;
          --db-password)  databasePassword="$2"; shift;;
          --db-username)  databaseUsername="$2"; shift;;
          --mongo-password)  mongoPassword="$2"; shift;;
          --mongo-username)  mongoUser="$2"; shift;;
          --mongo-database)  mongoDatabase="$2"; shift;;
          --mongo-port)  mongoPort="$2"; shift;;
          --mongo-host)  mongoHost="$2"; shift;;
          --mongo-uri)  mongoURI="$2"; shift;;
          --mongodopts)  mongodOpts="$2"; shift;;
	        --interchange-cookie-secret) interchangeCookieSecret="$2";shift;;
	        --interchange-cookie-name) interchangeCookieName="$2";shift;;
          --tomcat-memory)  tomcatMemory="$2"; shift;;
          --tomcat-password)  tomcatAdminPassword="$2"; shift;;
          --admin-user-email)     adminUsername="$2"; shift;;
          --admin-user-password)  defaultUserPassword="$2"; shift;;
          --admin-api-token)  defaultUserApiToken="$2"; shift;;
          --saml-alias)  samlAlias="$2"; shift;;
          --saml-password)  samlPassword="$2"; shift;;
          --no-apache)  apache=false;;
          --no-spidamin)  spidaMin=false;;
          --no-postgresql)  postgresql=false;;
          --no-mongodb)  mongo=false;;
          --no-start) dockerStart=false;;
          --has-docker) hasDockerConfig=true;;
          --disable-countdown) disableCountdown=true;;
          --default-apache-app)  defaultApacheApp="$2"; shift;;
          --sendgrid-api-key) sendgridApiKey="$2"; shift;;
          --alert-email) alertEmail="$2"; shift;;
          --email-host) emailHost="$2"; shift;;
          --email-port) emailPort="$2"; shift;;
          *)
              echo >&2 \
              "usage: $0 [option value]
                Options:
                  --tag                 docker spidamin tag to deploy (defaults to latest)
                  --postgresql-tag      docker postgresql tag to deploy (defaults to latest)
                  --mongodb-tag         docker mongodb tag to deploy (defaults to latest)
                  --redist-ag           docker mongodb tag to deploy (defaults to latest)
                  --apache-tag          docker apache tag to deploy (defaults to latest)
                  --docker-username     dockerhub username (will prompt for username if argument is not passed)
                  --docker-password     dockerhub password (will prompt for password if argument is not passed)
                  --server-root         server root that you will navigate to view the application (ex: min.com)
                  --backupdir           directory for mongo data, postgres data, files and backups (defaults to $backupDir). This has to be backed up.
                  --db-password         database password
                  --mongo-password      mongodb password
                  --mongodopts          mongod options
                  --tomcat-password     tomcat admin password
                  --tomcat-memory       tomcat maximum heap size
                  --user-password       default spidamin user password
                  --saml-alias          saml alias
                  --samlpassword        saml keystore password
                  --no-apache           don't add apache container
                  --no-spidamin         don't add spidamin container
                  --no-postgresql       don't add postgresql container
                  --no-mongodb          don't add mongodb container
                  --no-start            don't start any docker containers on completion
                  --has-docker          look for existing docker-compose.yml
                  --disable-countdown   turn off countdown jobs
                  --default-apache-app  default apache app to redirect to (defaults to projectmanager)
                  --sendgrid-api-key)   sendgrid apikey that will be used to send emails when there is an error in a cron backup job
                  --alert-email)        email address to send alerts to when a backup job fails
              "
              exit 1;;
      esac
      shift
  done

  if [[ ! -d "$backupDir" ]]; then
    echo "$backupDir does not exist, creating"
    mkdir -p "$backupDir/spida"
    echo "Done..."
  fi

  echo "--------------------------------------------------------------------------------------"
  echo "Data and files will be stored in ${backupDir}. You must take backups of this location."
  echo "--------------------------------------------------------------------------------------"
}

####################################################################################
#
# Check for docker
#
####################################################################################

function dockerCheck() {
	echo "Checking for docker"
	if [[ $(docker -v) == 'Docker version'* ]]; then
		echo "Docker daemon found"
	else
		echo "Docker not found. Please install Docker."
		echo "https://docs.docker.com/engine/install/"
		exit 1
	fi
	echo "Checking for docker compose"
	if [[ $(docker-compose -v) == 'docker-compose version'* ]]; then
		echo "Docker compose found"
	else
		echo "Docker compose not found. Please install Docker compose."
		echo "https://docs.docker.com/compose/install/linux/"
		exit 1
	fi
}


waitFor() {
  CMD=$1; shift
  CHECK_MSG=$1; shift;
  WAIT_MSG=$1; shift;
  UP_MSG=$1

  IS_UP=1
  while [ $IS_UP != 0 ]; do
    echo "$CHECK_MSG"
    eval "$CMD"
    IS_UP=$?
    if [ $IS_UP != 0 ]; then
      echo "$WAIT_MSG"
      sleep 60
    fi
  done
  echo "$UP_MSG"
}

waitForService() {
  waitFor \
    "sudo docker ps | grep -q '$1'" \
    "Checking if $1 is up..." \
    "$1 is not up, waiting..." \
    "$1 is up"
}

####################################################################################
#
# Logs in to Docker
#
####################################################################################
function dockerLogin() {
  if [[ "$dockerUsername" = "" ]]; then
    read -r -p "Docker username: " dockerUsername
  fi

  if [[ "$dockerPassword" = "" ]]; then
  	read -r -s -p "Docker password: " dockerPassword
  fi

  docker login -u "$dockerUsername" -p "$dockerPassword"

  if [ $? -ne 0 ]; then
    echo "login failed, unable to connect to docker repository."
  fi
}


####################################################################################
#
# Generates docker-compose.yml
#
####################################################################################
function createDockerComposeFile() {
  echo "Creating the docker-compose.yml file"
  dockerComposeFile=$appconfigDir/docker-compose.yml
  dockerEnvFile=$appconfigDir/.docker-common.env
  mkdir -p "$appconfigDir"
  sudo rm -f "$dockerComposeFile"
  sudo touch "$dockerComposeFile"

  sudo rm -f "$dockerEnvFile"
  sudo touch "$dockerEnvFile"

  # SQL Database Configuration (Postgres,Oracle,etc.)
  if [[ -n "$databaseUsername" ]]; then
    echo "DATABASE_USERNAME=$databaseUsername" >> "$dockerEnvFile"
  fi
  if [[ -n "$databasePassword" ]]; then
    echo "DATABASE_PASSWORD=$databasePassword" >> "$dockerEnvFile"
    echo "POSTGRES_PASSWORD=$databasePassword" >> "$dockerEnvFile"
  fi
  if [[ -n "$databaseConnStr" ]]; then
    echo "DATABASE_CONNECTION_STRING=$databaseConnStr" >> "$dockerEnvFile"
  fi
  if [[ -n "$databaseDriver" ]]; then
    echo "DATABASE_DRIVER=$databaseDriver" >> "$dockerEnvFile"
  fi

  # MongoDB Configuration
  if [[ -n "$mongoPassword" ]]; then
    echo "MONGODB_PASSWORD=$mongoPassword" >> "$dockerEnvFile"
  fi
  if [[ -n "$mongoUser" ]]; then
    echo "MONGODB_USERNAME=$mongoUser" >> "$dockerEnvFile"
  fi
  if [[ -n "$mongoDatabase" ]]; then
        echo "MONGODB_DATABASE=$mongoDatabase" >> "$dockerEnvFile"
  fi
  if [[ -n "$mongoPort" ]]; then
        echo "MONGODB_PORT=$mongoPort" >> "$dockerEnvFile"
  fi
  if [[ -n "$mongoHost" ]]; then
        echo "MONGODB_HOST=$mongoHost" >> "$dockerEnvFile"
  fi
  if [[ -n "$mongoURI" ]]; then
        echo "MONGODB_URI=$mongoURI" >> "$dockerEnvFile"
  fi

  # Tomcat Configuration
  if [[ -n "$tomcatAdminPassword" ]]; then
    echo "TOMCAT_PASSWORD=$tomcatAdminPassword" >> "$dockerEnvFile"
  fi
  if [[ -n "$tomcatMemory" ]]; then
    echo "TOMCAT_MAX_MEMORY_MB=${tomcatMemory}" >> "$dockerEnvFile"
  fi

  # SPIDA Studio Application Configuration
  if [[ $disableCountdown = true ]]; then
    echo "COUNTDOWN_DISABLED=true" >> "$dockerEnvFile"
  fi
  if [[ -n "$sendgridApiKey" ]]; then
    echo "BACKUP_JOBS_SENDGRID_API_KEY=${sendgridApiKey}" >> "$dockerEnvFile"
  fi
  if [[ -n "$defaultUserApiToken" ]]; then
    echo "ADMIN_API_TOKEN=$defaultUserApiToken" >> "$dockerEnvFile"
  fi
  if [[ -n "$defaultUserPassword" ]]; then
    echo "ADMIN_USER_PASSWORD=$defaultUserPassword" >> "$dockerEnvFile"
  fi
  if [[ -n "$adminUsername" ]]; then
    echo "ADMIN_USER_EMAIL=$adminUsername" >> "$dockerEnvFile"
  fi

  # SAML Config
  if [[ -n "$samlPassword" ]]; then
    echo "SAML_PW=${samlPassword}" >> "$dockerEnvFile"
  fi
  if [[ -n "$samlAlias" ]]; then
    echo "SAML_ALIAS=${samlAlias}" >> "$dockerEnvFile"
  fi

  # SPIDA Application E-mail Config
  if [[ -n "$emailPort" ]]; then
    echo "EMAIL_PORT=${emailPort}" >> "$dockerEnvFile"
  fi
  if [[ -n "$emailHost" ]]; then
    echo "EMAIL_HOST=${emailHost}" >> "$dockerEnvFile"
  fi
  if [[ -n "$alertEmail" ]]; then
    echo "ALERT_EMAIL=${alertEmail}" >> "$dockerEnvFile"
  fi

  # setup mongo data dir, postgres data dir, files dir, and backup dir
  if [[ $postgresql = true ]]; then
    postgresBackupDir="${backupDir}/postgresBackups"
    postgresDataDir="${backupDir}/postgresData"
  fi

  if [[ $mongo = true ]]; then
    mongoBackupDir="${backupDir}/mongoBackups"
    mongoDataDir="${backupDir}/mongoData"
    mongoLogDir="${backupDir}/logs/mongodb"
  fi

  if [[ $apache = true ]]; then
    apachessl="${backupDir}/ssl"
    apacheLogs="${backupDir}/logs/apache"
  fi

  if [[ $spidaMin = true ]]; then
    filesDir="${backupDir}/files"
    spidaLogs="${backupDir}/logs/spida"
    tomcatLogs="${backupDir}/logs/tomcat"
    geoserver="${backupDir}/geoserver"
    tomcatssl="${backupDir}/ssl"
    samlDir="${backupDir}/saml"
  fi

  mkdir -p $filesDir $spidaLogs $tomcatLogs $tomcatssl $geoserver $samlDir \
  $mongoBackupDir $mongoDataDir $mongoLogDir \
  $apachessl $apacheLogs \
  $postgresBackupDir $postgresDataDir

  HOST_MACHINE_HOST_NAME=$(hostname -f)

  if [[ $spidaMin = true ]]; then
    echo "spidamin:
  image: spidasoftware/min:$tag
  restart: always
  volumes:
    - $filesDir:/var/lib/spida/files
    - $geoserver:/var/lib/spida/geoserver
    - $tomcatssl:/var/lib/spida/ssl
    - $tomcatLogs:/usr/local/tomcat/logs
    - $spidaLogs:/var/lib/spida/logs
    - $samlDir:/var/lib/spida/saml
  environment:
    - HOST_MACHINE_HOST_NAME=$HOST_MACHINE_HOST_NAME" >> "$dockerComposeFile"

    if [[ "$serverRoot" != "" ]]; then
      echo "    - SERVER_ROOT=$serverRoot" >> "$dockerComposeFile"
    fi

    { echo "  env_file: $dockerEnvFile";
      echo "  links:";
      echo "    - redis"; } >> "$dockerComposeFile"

    if [[ $postgresql = true ]]; then
      echo "    - postgresql" >> "$dockerComposeFile"
    fi
    if [[ $mongo = true ]]; then
      echo "    - mongodb" >> "$dockerComposeFile"
    fi
    echo "redis:
  image: spidasoftware/redis:$redisTag
  restart: always" >> "$dockerComposeFile"
  fi

  if [[ $postgresql = true ]]; then
    if [[ "$serverRoot" != "" ]]; then
      POSTGRES_HOSTNAME="postgresql.${serverRoot}"
    else
      POSTGRES_HOSTNAME="postgresql.${HOST_MACHINE_HOST_NAME}"
    fi
    echo "postgresql:
  image: spidasoftware/postgresql:$postgresqlTag
  restart: always
  hostname: $POSTGRES_HOSTNAME
  volumes:
    - $postgresBackupDir:/backups
    - $postgresDataDir:/var/lib/postgresql/data
  env_file: $dockerEnvFile" >> "$dockerComposeFile"
  fi

  if [[ $mongo = true ]]; then
    if [[ "$serverRoot" != "" ]]; then
      MONGODB_HOSTNAME="mongodb.${serverRoot}"
    else
      MONGODB_HOSTNAME="mongodb.${HOST_MACHINE_HOST_NAME}"
    fi
    echo "mongodb:
  image: spidasoftware/mongodb:$mongodbTag
  restart: always
  hostname: $MONGODB_HOSTNAME
  volumes:
    - $mongoBackupDir:/backups
    - $mongoDataDir:/data/db
    - $mongoLogDir:/var/log/mongodb
  env_file: $dockerEnvFile" >> "$dockerComposeFile"
    if [[ "$mongodOpts" != "" ]]; then
      echo "  environment:
    - MONGOD_OPTS=$mongodOpts" >> "$dockerComposeFile"
    fi
  fi

  if [[ $apache = true ]]; then
        echo "apache:
      image: spidasoftware/apache:$apacheTag
      restart: always
      links:
        - spidamin
      ports:
        - \"80:80\"
        - \"443:443\"
      volumes:
        - $apachessl:/var/lib/spida/apache_ssl
        - $apacheLogs:/var/log/apache2
      environment:
        - HOST_MACHINE_HOST_NAME=$HOST_MACHINE_HOST_NAME" >> "$dockerComposeFile"

        if [[ "$serverRoot" != "" ]]; then
          echo "      - SERVER_ROOT=$serverRoot" >> "$dockerComposeFile"
        fi
        if [[ "$defaultApacheApp" != "" ]]; then
          echo "      - DEFAULT_APP_NAME=$defaultApacheApp" >> "$dockerComposeFile"
        fi
  fi
}

####################################################################################
#
# Updates docker-compose.yml
#
####################################################################################
function updateDockerComposeFile() {
  dockerComposeFile=$appconfigDir/docker-compose.yml
  HOST_MACHINE_HOST_NAME=$(hostname -f)

  #We may still want to override the COUNTDOWN_DISABLED var
  dockerEnvFile=$appconfigDir/.docker-common.env
  sed -i '/COUNTDOWN_DISABLED/d' "$dockerEnvFile"
  if [[ $disableCountdown = true ]]; then
    echo "COUNTDOWN_DISABLED=true" >> "$dockerEnvFile"
  fi

  # Update the server root and the host machine
  sed -i "s/\s*- SERVER_ROOT=\S*$/    - SERVER_ROOT=${serverRoot}/g" "$dockerComposeFile"
  sed -i "s/\s*- HOST_MACHINE_HOST_NAME=\S*$/    - HOST_MACHINE_HOST_NAME=${HOST_MACHINE_HOST_NAME}/g" "$dockerComposeFile"

  # Update the docker image tags, if they were passed in, they aren't latest.
  if [ $MIN_TAG_PASSED = true ]; then
    sed -i "s/spidasoftware\/min:\S*$/spidasoftware\/min:$tag/g" "$dockerComposeFile"
  fi
  if [ $POSTGRESQL_TAG_PASSED = true ]; then
    sed -i "s/spidasoftware\/postgresql:\S*$/spidasoftware\/postgresql:${postgresqlTag}/" "$dockerComposeFile"
  fi
  if [ $MONGODB_TAG_PASSED = true ]; then
    sed -i "s/spidasoftware\/mongodb:\S*$/spidasoftware\/mongodb:${mongodbTag}/" "$dockerComposeFile"
  fi
  if [ $REDIS_TAG_PASSED = true ]; then
    sed -i "s/spidasoftware\/redis:\S*$/spidasoftware\/redis:${redisTag}/" "$dockerComposeFile"
  fi
  if [ $APACHE_TAG_PASSED = true ]; then
    sed -i "s/spidasoftware\/apache:\S*$/spidasoftware\/apache:${apacheTag}/" "$dockerComposeFile"
  fi

  POSTGRES_HOSTNAME="postgresql.${HOST_MACHINE_HOST_NAME}"
  if [[ "$serverRoot" != "" ]]; then
    POSTGRES_HOSTNAME="postgresql.${serverRoot}"
  fi
  sed -i "s/\s*hostname: postgresql\.\S*/  hostname: ${POSTGRES_HOSTNAME}/" "$dockerComposeFile"

  MONGODB_HOSTNAME="mongodb.${HOST_MACHINE_HOST_NAME}"
  if [[ "$serverRoot" != "" ]]; then
    MONGODB_HOSTNAME="mongodb.${serverRoot}"
  fi
  sed -i "s/\s*hostname: mongodb\.\S*/  hostname: ${MONGODB_HOSTNAME}/" "$dockerComposeFile"

  # Update the passwords, if they're passed in
  if [[ -n "$databasePassword" ]]; then
    sed -i "/DATABASE_PASSWORD=\S*$/d" "$dockerEnvFile"
    sed -i "/POSTGRES_PASSWORD=\S*$/d" "$dockerEnvFile"
    echo "DATABASE_PASSWORD=$databasePassword" >> "$dockerEnvFile"
    echo "POSTGRES_PASSWORD=$databasePassword" >> "$dockerEnvFile"
  fi
  if [[ -n "$mongoPassword" ]]; then
    sed -i "/MONGODB_PASSWORD=\S*$/d" "$dockerEnvFile"
    echo "MONGODB_PASSWORD=$mongoPassword" >> "$dockerEnvFile"
    rm "$backupDir"/mongoData/.mongodb_password_set
  fi
  if [[ -n "$tomcatAdminPassword" ]]; then
    sed -i "/TOMCAT_PASSWORD=\S*$/d" "$dockerEnvFile"
    echo "TOMCAT_PASSWORD=$tomcatAdminPassword" >> "$dockerEnvFile"
  fi
  if [[ -n "$defaultUserPassword" ]]; then
    sed -i "/ADMIN_USER_PASSWORD=\S*$/d" "$dockerEnvFile"
    echo "ADMIN_USER_PASSWORD=$defaultUserPassword" >> "$dockerEnvFile"
  fi
  if [[ -n "$defaultUserApiToken" ]]; then
    sed -i "/ADMIN_API_TOKEN=\S*$/d" "$dockerEnvFile"
    echo "ADMIN_API_TOKEN=$defaultUserApiToken" >> "$dockerEnvFile"
  fi
  if [[ -n "$sendgridApiKey" ]]; then
    sed -i "/BACKUP_JOBS_SENDGRID_API_KEY=\S*$/d" "$dockerEnvFile"
    echo "BACKUP_JOBS_SENDGRID_API_KEY=${sendgridApiKey}" >> "$dockerEnvFile"
  fi
  if [[ -n "$alertEmail" ]]; then
    sed -i "/ALERT_EMAIL=\S*$/d" "$dockerEnvFile"
    echo "ALERT_EMAIL=${alertEmail}" >> "$dockerEnvFile"
  fi
  if [[ -n "$samlPassword" ]]; then
    sed -i "/SAML_PASSWORD=\S*$/d" "$dockerEnvFile"
      echo "SAML_PASSWORD=${samlPassword}" >> "$dockerEnvFile"
  fi
  if [[ -n "$interchangeCookieName" ]]; then
      echo "INTERCHANGE_TOKEN_NAME=${interchangeCookieName}" >> "$dockerEnvFile"
  fi
  if [[ -n "$interchangeCookieSecret" ]]; then
      echo "INTERCHANGE_CS=${interchangeCookieSecret}" >> "$dockerEnvFile"
  fi

  unset dockerEnvFile
}

####################################################################################
#
# Setup docker container log rotation
#
####################################################################################
function setupLogRotate() {
  sudo touch /etc/logrotate.d/docker-container
  echo "/var/lib/docker/containers/*/*.log {
  rotate 7
  daily
  compress
  size=1G
  missingok
  copytruncate
}" >> /etc/logrotate.d/docker-container
}

####################################################################################
#
# Add Company Details to .docker-common.env file.
#
####################################################################################
function addCompanyDetails() {
  dockerEnvFile=$appconfigDir/.docker-common.env
  if [[ -f "$dockerEnvFile" ]]; then
    if [[ $COMPANY_NAME ]]; then
      echo "COMPANY_NAME=$COMPANY_NAME" >> "$dockerEnvFile"
    fi
    if [[ $COMPANY_ADDRESS ]]; then
      echo "COMPANY_ADDRESS=$COMPANY_ADDRESS" >> "$dockerEnvFile"
    fi
    if [[ $COMPANY_ADDRESS_2 ]]; then
      echo "COMPANY_ADDRESS_2=$COMPANY_COMPANY_ADDRESS_2" >> "$dockerEnvFile"
    fi
    if [[ $COMPANY_PHONE ]]; then
      echo "COMPANY_PHONE=$COMPANY_PHONE" >> "$dockerEnvFile"
    fi
    if [[ $COMPANY_CITY ]]; then
      echo "COMPANY_CITY=$COMPANY_CITY" >> "$dockerEnvFile"
    fi
    if [[ $COMPANY_LOCAL ]]; then
      echo "COMPANY_LOCAL=$COMPANY_LOCAL" >> "$dockerEnvFile"
    fi
    if [[ $COMPANY_POSTAL ]]; then
      echo "COMPANY_POSTAL=$COMPANY_POSTAL" >> "$dockerEnvFile"
    fi
    if [[ $COMPANY_COUNTRY ]]; then
      echo "COMPANY_COUNTRY=$COMPANY_COUNTRY" >> "$dockerEnvFile"
    fi
    if [[ $COMPANY_NAME ]]; then
      echo "COMPANY_NAME=$COMPANY_NAME" >> "$dockerEnvFile"
    fi
    if [[ $COMPANY_NAME ]]; then
      echo "COMPANY_NAME=$COMPANY_NAME" >> "$dockerEnvFile"
    fi
  fi
}

createEmptyLogs() {
  # Create Empty Log Files
  touch /apps/spidamin/logs/spida/projectmanager.log \
   /apps/spidamin/logs/spida/assetmaster.log /apps/spidamin/logs/spida/calcdb.log \
   /apps/spidamin/logs/spida/filefort.log /apps/spidamin/logs/spida/geoserver.log \
   /apps/spidamin/logs/spida/licensemanager.log /apps/spidamin/logs/spida/monitor.log \
   /apps/spidamin/logs/spida/spidadb.log /apps/spidamin/logs/spida/usersmaster.log \
   /apps/spidamin/logs/spida/am_performance.log /apps/spidamin/logs/spida/db_performance.log \
   /apps/spidamin/logs/spida/ff_performance.log /apps/spidamin/logs/spida/pm_performance.log \
   /apps/spidamin/logs/spida/um_performance.log /apps/spidamin/logs/tomcat/catalina.out
}
####################################################################################
#
# Execute above functions
#
####################################################################################
parseCommandLineArguments "$@"
dockerCheck
dockerLogin

if [ $hasDockerConfig = false -o ! \( -f "$appconfigDir"/docker-compose.yml -a -f "$appconfigDir"/.docker-common.env \) ]; then
  updatePasswords=false
  createDockerComposeFile
else
  updateDockerComposeFile
  updatePasswords=true
fi

addCompanyDetails
setupLogRotate
createEmptyLogs

dockerComposeFile=$appconfigDir/docker-compose.yml

if [ $updatePasswords = true ] && [ $postgresql = true ]; then
  sudo docker-compose -f "$dockerComposeFile" up -d postgresql
  waitForService postgresql
  sleep 30
  sudo docker exec spida_postgresql_1 /reset-passwords.sh
fi

if [ $dockerStart = true ]; then
  sudo docker-compose -f "$dockerComposeFile" up -d
else
  if [ $updatePasswords = true ]; then
    sudo docker-compose -f "$dockerComposeFile" down
  fi
  sudo docker-compose -f "$dockerComposeFile" pull
fi
sudo docker logout
