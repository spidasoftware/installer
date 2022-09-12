#!/bin/sh

####################################################################################
serverRoot=`hostname -f`
dockerUsername=""
dockerPassword=""
databasePassword=""
mongoPassword=""
tomcatAdminPassword=""
defaultUserPassword=""
samlPassword=""
defaulUserApiToken=""
spidaMin=true
postgresql=true
mongo=true
dockerStart=true
hasDockerConfig=false
disableCountdown=false
backupDir="/apps/spidamin"
configDir="/etc/spida"
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
defaultApacheApp=""
sendgridApiKey=""
alertEmail=""

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
          --postgresqltag)  postgresqlTag="$2"; POSTGRESQL_TAG_PASSED=true; shift;;
          --mongodbtag)  mongodbTag="$2"; MONGODB_TAG_PASSED=true; shift;;
          --redistag)  redisTag="$2"; REDIS_TAG_PASSED=true; shift;;
          --apachetag)  apacheTag="$2"; APACHE_TAG_PASSED=true; shift;;
          --serverroot)  serverRoot="$2"; shift;;
          --username)  dockerUsername="$2"; shift;;
          --password)  dockerPassword="$2"; shift;;
          --backupdir)  backupDir="$2"; shift;;
          --configdir)  configDir="$2"; shift;;
          --dbpassword)  databasePassword="$2"; shift;;
          --mongopassword)  mongoPassword="$2"; shift;;
          --tomcatpassword)  tomcatAdminPassword="$2"; shift;;
          --userpassword)  defaultUserPassword="$2"; shift;;
          --samlpassword)  samlPassword="$2"; shift;;
          --apitoken)  defaulUserApiToken="$2"; shift;;
          --no-spidamin)  spidaMin=false;;
          --no-postgresql)  postgresql=false;;
          --no-mongodb)  mongo=false;;
          --no-start) dockerStart=false;;
    		  --has-docker) hasDockerConfig=true;;
    		  --disable-countdown) disableCountdown=true;;
          --default-apache-app)  defaultApacheApp="$2"; shift;;
          --sendgrid-api-key) sendgridApiKey="$2"; shift;;
          --alert-email) alertEmail="$2"; shift;;
          *)
              echo >&2 \
              "usage: $0 [option value]
                Options:
                  --tag                 docker spidamin tag to deploy (defaults to latest)
                  --postgresqltag       docker postgresql tag to deploy (defaults to latest)
                  --mongodbtag          docker mongodb tag to deploy (defaults to latest)
                  --redistag            docker mongodb tag to deploy (defaults to latest)
                  --apachetag           docker apache tag to deploy (defaults to latest)
                  --username            dockerhub username (will prompt for username if argument is not passed)
                  --password            dockerhub password (will prompt for password if argument is not passed)
                  --serverroot          server root that you will navigate to view the application (ex: min.com)
                  --backupdir           directory for mongo data, postgres data, files and backups (defaults to $backupDir). This has to be backed up.
                  --configdir           directory for configuration and scripts (defaults to $configDir).
                  --dbpassword          database password
                  --mongopassword       mongodb password
                  --tomcatpassword      tomcat admin password
                  --userpassword        default spidamin user password
                  --samlpassword        saml keystore password
                  --no-spidamin         don't install spidamin
                  --no-postgresql       don't install postgresql
                  --no-mongodb          don't install mongodb
				          --no-start            don't start any docker containers
				          --has-docker          look for existing docker-compose.yml
				          --disable-countdown   turn off countdown jobs
                  --default-apache-app  default apache app to redirect to (defaults to projectmanager)
                  --sendgrid-api-key)   sendgrid apikey that will be used to send emails when there is an error in a cron backup job
                  --alert-email)        email address to send alerts to when a backup job fails
              "
              exit 1;;
          *)  break;; # terminate while loop
      esac
      shift
  done

  if [[ ! -d "$backupDir" ]]; then
    echo "$backupDir does not exist, exiting"
    exit 1
  fi

  echo "--------------------------------------------------------------------------------------"
  echo "Data and files will be stored in ${backupDir}. You must take backups of this location."
  echo "--------------------------------------------------------------------------------------"
}

waitFor() {
  CMD=$1; shift
  CHECK_MSG=$1; shift;
  WAIT_MSG=$1; shift;
  UP_MSG=$1

  IS_UP=1
  while [ $IS_UP != 0 ]; do
    echo "$CHECK_MSG"
    eval $CMD
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
	if [[$(docker-compose -v) == 'docker-compose version'* ]]; then
		echo "Docker compose found"
	else 
		echo "Docker compose not found. Please install Docker compose."
		echo "https://docs.docker.com/compose/install/linux/"
		exit 1
	fi
}

####################################################################################
#
# Generates docker-compose.yml
#
####################################################################################
function createDockerComposeFile() {
  echo "Creating the docker-compose.yml file"
  needEnvFile=false
  if [[ "$databasePassword" != "" || "$mongoPassword" != "" || "$tomcatAdminPassword" != "" || "$defaultUserPassword" != "" || "$defaulUserApiToken" != "" || "$sendgridApiKey" != "" || "$alertEmail" != "" ]]; then
    needEnvFile=true
  fi

  dockerComposeFile=$configDir/docker-compose.yml
  dockerEnvFile=$configDir/.docker-common.env
  mkdir -p $configDir
  sudo rm -f $dockerComposeFile
  sudo touch $dockerComposeFile

  if [[ $needEnvFile = true ]]; then
    sudo rm -f $dockerEnvFile
    sudo touch $dockerEnvFile
    if [[ -n "$databasePassword" ]]; then
      echo "DATABASE_PASSWORD=$databasePassword" >> $dockerEnvFile
      echo "POSTGRES_PASSWORD=$databasePassword" >> $dockerEnvFile
    fi
    if [[ -n "$mongoPassword" ]]; then
      echo "MONGODB_PASSWORD=$mongoPassword" >> $dockerEnvFile
    fi
    if [[ -n "$tomcatAdminPassword" ]]; then
      echo "TOMCAT_PASSWORD=$tomcatAdminPassword" >> $dockerEnvFile
    fi
    if [[ -n "$defaultUserPassword" ]]; then
      echo "ADMIN_USER_PASSWORD=$defaultUserPassword" >> $dockerEnvFile
    fi
    if [[ -n "$defaulUserApiToken" ]]; then
      echo "ADMIN_API_TOKEN=$defaulUserApiToken" >> $dockerEnvFile
    fi
  	if [[ -n "$disableCountdown" ]]; then
  	  echo "COUNTDOWN_DISABLED='true'" >> $dockerEnvFile
  	fi
    if [[ -n "$sendgridApiKey" ]]; then
      echo "BACKUP_JOBS_SENDGRID_API_KEY=${sendgridApiKey}" >> $dockerEnvFile
    fi
    if [[ -n "$alertEmail" ]]; then
      echo "ALERT_EMAIL=${alertEmail}" >> $dockerEnvFile
    fi
    if [[ -n "$samlPassword" ]]; then
      echo "SAML_PW=${samlPassword}" >> $dockerEnvFile
    fi
  fi

  # setup mongo data dir, postgres data dir files dir and backsup dir
  filesDir="${backupDir}/files"
  postgresBackupDir="${backupDir}/postgresBackups"
  mongoBackupDir="${backupDir}/mongoBackups"
  mongoDataDir="${backupDir}/mongoData"
  postgresDataDir="${backupDir}/postgresData"
  apachessl="${backupDir}/apachessl"
  geoserver="${backupDir}/geoserver"
  tomcatLogs="${backupDir}/logs/tomcat"
  spidaLogs="${backupDir}/logs/spida"
  apacheLogs="${backupDir}/logs/apache"
  mkdir -p $filesDir $postgresBackupDir $mongoBackupDir $mongoDataDir $postgresDataDir $apachessl $geoserver $tomcatLogs $spidaLogs $apacheLogs

  HOST_MACHINE_HOST_NAME=`hostname -f`
  if [[ $spidaMin = true ]]; then
    echo "spidamin:
  image: spidasoftware/min:$tag
  restart: always
  volumes:
    - $filesDir:/var/lib/spida/files
    - $geoserver:/var/lib/spida/geoserver
    - $tomcatLogs:/usr/local/tomcat/logs
    - $spidaLogs:/var/lib/spida/logs
  environment:
    - HOST_MACHINE_HOST_NAME=$HOST_MACHINE_HOST_NAME" >> $dockerComposeFile

    if [[ "$serverRoot" != "" ]]; then
      echo "    - SERVER_ROOT=$serverRoot" >> $dockerComposeFile
    fi

    if [[ $needEnvFile = true ]]; then
      echo "  env_file: $dockerEnvFile" >> $dockerComposeFile
    fi

    echo "  links:" >> $dockerComposeFile
    echo "    - redis" >> $dockerComposeFile
    if [[ $postgresql = true ]]; then
      echo "    - postgresql" >> $dockerComposeFile
    fi
    if [[ $mongo = true ]]; then
      echo "    - mongodb" >> $dockerComposeFile
    fi
  fi

  if [[ $postgresql = true ]]; then
    POSTGRES_HOSTNAME="postgresql.${HOST_MACHINE_HOST_NAME}"
    if [[ "$serverRoot" != "" ]]; then
      POSTGRES_HOSTNAME="postgresql.${serverRoot}"
    fi
    echo "postgresql:
  image: spidasoftware/postgresql:$postgresqlTag
  restart: always
  hostname: $POSTGRES_HOSTNAME
  volumes:
    - $postgresBackupDir:/backups
    - $postgresDataDir:/var/lib/postgresql/data" >> $dockerComposeFile
      if [[ $needEnvFile = true ]]; then
        echo "  env_file: $dockerEnvFile" >> $dockerComposeFile
      fi
  fi

  if [[ $mongo = true ]]; then
    MONGODB_HOSTNAME="mongodb.${HOST_MACHINE_HOST_NAME}"
    if [[ "$serverRoot" != "" ]]; then
      MONGODB_HOSTNAME="mongodb.${serverRoot}"
    fi
    echo "mongodb:
  image: spidasoftware/mongodb:$mongodbTag
  restart: always
  hostname: $MONGODB_HOSTNAME
  volumes:
    - $mongoBackupDir:/backups
    - $mongoDataDir:/data/db" >> $dockerComposeFile
      if [[ $needEnvFile = true ]]; then
        echo "  env_file: $dockerEnvFile" >> $dockerComposeFile
      fi
  fi

  if [[ $spidaMin = true ]]; then
    echo "redis:
  image: spidasoftware/redis:$redisTag
  restart: always" >> $dockerComposeFile

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
    - HOST_MACHINE_HOST_NAME=$HOST_MACHINE_HOST_NAME" >> $dockerComposeFile

    if [[ "$serverRoot" != "" ]]; then
      echo "    - SERVER_ROOT=$serverRoot" >> $dockerComposeFile
    fi
    if [[ "$defaultApacheApp" != "" ]]; then
      echo "    - DEFAULT_APP_NAME=$defaultApacheApp" >> $dockerComposeFile
    fi
  fi
}

####################################################################################
#
# Updates docker-compose.yml
#
####################################################################################
function updateDockerComposeFile() {
  dockerComposeFile=$configDir/docker-compose.yml
  HOST_MACHINE_HOST_NAME=`hostname -f`

  #We may still want to override the COUNTDOWN_DISABLED var
  dockerEnvFile=$configDir/.docker-common.env
  sed -i '/COUNTDOWN_DISABLED/d' $dockerEnvFile
  if [[ $disableCountdown = true ]]; then
    echo "COUNTDOWN_DISABLED='true'" >> $dockerEnvFile
  fi

  # Update the server root and the host machine
  sed -i "s/\s*- SERVER_ROOT=\S*$/    - SERVER_ROOT=${serverRoot}/g" $dockerComposeFile
  sed -i "s/\s*- HOST_MACHINE_HOST_NAME=\S*$/    - HOST_MACHINE_HOST_NAME=${HOST_MACHINE_HOST_NAME}/g" $dockerComposeFile

  # Update the docker image tags, if they were passed in, they aren't latest.
  if [ $MIN_TAG_PASSED = true ]; then
    sed -i "s/spidasoftware\/min:\S*$/spidasoftware\/min:$tag/g" $dockerComposeFile
  fi
  if [ $POSTGRESQL_TAG_PASSED = true ]; then
    sed -i "s/spidasoftware\/postgresql:\S*$/spidasoftware\/postgresql:${postgresqlTag}/" $dockerComposeFile
  fi
  if [ $MONGODB_TAG_PASSED = true ]; then
    sed -i "s/spidasoftware\/mongodb:\S*$/spidasoftware\/mongodb:${mongodbTag}/" $dockerComposeFile
  fi
  if [ $REDIS_TAG_PASSED = true ]; then
    sed -i "s/spidasoftware\/redis:\S*$/spidasoftware\/redis:${redisTag}/" $dockerComposeFile
  fi
  if [ $APACHE_TAG_PASSED = true ]; then
    sed -i "s/spidasoftware\/apache:\S*$/spidasoftware\/apache:${apacheTag}/" $dockerComposeFile
  fi

  POSTGRES_HOSTNAME="postgresql.${HOST_MACHINE_HOST_NAME}"
  if [[ "$serverRoot" != "" ]]; then
    POSTGRES_HOSTNAME="postgresql.${serverRoot}"
  fi
  sed -i "s/\s*hostname: postgresql\.\S*/  hostname: ${POSTGRES_HOSTNAME}/" $dockerComposeFile

  MONGODB_HOSTNAME="mongodb.${HOST_MACHINE_HOST_NAME}"
  if [[ "$serverRoot" != "" ]]; then
    MONGODB_HOSTNAME="mongodb.${serverRoot}"
  fi
  sed -i "s/\s*hostname: mongodb\.\S*/  hostname: ${MONGODB_HOSTNAME}/" $dockerComposeFile

  # Update the passwords, if they're passed in
  if [[ -n "$databasePassword" ]]; then
    sed -i "/DATABASE_PASSWORD=\S*$/d" $dockerEnvFile
    sed -i "/POSTGRES_PASSWORD=\S*$/d" $dockerEnvFile
    echo "DATABASE_PASSWORD=$databasePassword" >> $dockerEnvFile
    echo "POSTGRES_PASSWORD=$databasePassword" >> $dockerEnvFile
  fi
  if [[ -n "$mongoPassword" ]]; then
    sed -i "/MONGODB_PASSWORD=\S*$/d" $dockerEnvFile
    echo "MONGODB_PASSWORD=$mongoPassword" >> $dockerEnvFile
    rm $backupDir/mongoData/.mongodb_password_set
  fi
  if [[ -n "$tomcatAdminPassword" ]]; then
    sed -i "/TOMCAT_PASSWORD=\S*$/d" $dockerEnvFile
    echo "TOMCAT_PASSWORD=$tomcatAdminPassword" >> $dockerEnvFile
  fi
  if [[ -n "$defaultUserPassword" ]]; then
    sed -i "/ADMIN_USER_PASSWORD=\S*$/d" $dockerEnvFile
    echo "ADMIN_USER_PASSWORD=$defaultUserPassword" >> $dockerEnvFile
  fi
  if [[ -n "$defaulUserApiToken" ]]; then
    sed -i "/ADMIN_API_TOKEN=\S*$/d" $dockerEnvFile
    echo "ADMIN_API_TOKEN=$defaulUserApiToken" >> $dockerEnvFile
  fi
  if [[ -n "$sendgridApiKey" ]]; then
    sed -i "/BACKUP_JOBS_SENDGRID_API_KEY=\S*$/d" $dockerEnvFile
    echo "BACKUP_JOBS_SENDGRID_API_KEY=${sendgridApiKey}" >> $dockerEnvFile
  fi
  if [[ -n "$alertEmail" ]]; then
    sed -i "/ALERT_EMAIL=\S*$/d" $dockerEnvFile
    echo "ALERT_EMAIL=${alertEmail}" >> $dockerEnvFile
  fi
  if [[ -n "$samlPassword" ]]; then
    sed -i "/SAML_PASSWORD=\S*$/d" $dockerEnvFile
      echo "SAML_PASSWORD=${samlPassword}" >> $dockerEnvFile
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
# Execute above functions
#
####################################################################################
parseCommandLineArguments $@

dockerCheck

if [ $hasDockerConfig = false -o ! \( -f $configDir/docker-compose.yml -a -f $configDir/.docker-common.env \) ]; then
  updatePasswords=false
	createDockerComposeFile
else
  updateDockerComposeFile
  updatePasswords=true
fi
setupLogRotate

dockerComposeFile=$configDir/docker-compose.yml
if [ $updatePasswords = true ] && [ $postgresql = true ]; then
  sudo docker-compose -f $dockerComposeFile up -d postgresql
  waitForService postgresql
  sleep 30
  sudo docker exec spida_postgresql_1 /reset-passwords.sh
fi

if [ $dockerStart = true ]; then
	sudo docker-compose -f $dockerComposeFile up -d
else
  if [ $updatePasswords = true ]; then
    sudo docker-compose -f $dockerComposeFile down
  fi
	sudo docker-compose -f $dockerComposeFile pull
fi
