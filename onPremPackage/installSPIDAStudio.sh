#!/bin/bash
set -x

# Installation Configuration File
source conf/spidaInstall.conf

if [[ -f ${CONTAINER_PACKAGE} ]];then
  docker load -i "${CONTAINER_PACKAGE}"
else
  echo "No container package found locally. If this is unexpected please check the 'CONTAINER_PACKAGE' configuration."
fi

# Containers to Install
CONTAINERS=""
if [[ "$INSTALL_APACHE" == "n" ]];then
  CONTAINERS+="--no-apache "
fi
if [[ "$INSTALL_STUDIO" == "n" ]];then
  CONTAINERS+="--no-spidamin "
fi
if [[ "$INSTALL_MONGODB" == "n" ]];then
  CONTAINERS+="--no-mongo "
fi
if [[ "$INSTALL_POSTGRES" == "n" ]];then
  CONTAINERS+="--no-postgresql "
fi

# Setup Docker Container Tag Flags
TAGS=""
if [[ $STUDIO_TAG ]];then
  TAGS+="--tag $STUDIO_TAG "
fi
if [[ $REDIS_TAG ]];then
  TAGS+="--redis-tag $REDIS_TAG "
fi
if [[ $PSQL_TAG ]];then
  TAGS+="--postgresql-tag $PSQL_TAG "
fi
if [[ $MONGO_TAG ]];then
  TAGS+="--mongodb-tag $MONGO_TAG "
fi
if [[ $APACHE_TAG ]];then
  TAGS+="--apache-tag $APACHE_TAG "
fi

# Setup Mongo Flags
MONGO=""
if [[ $MONGODB_DBNAME ]]; then
  MONGO="--mongo-database $MONGODB_DBNAME "
fi
if [[ $MONGODB_USERNAME ]]; then
  MONGO+="--mongo-username $MONGODB_USERNAME "
fi
if [[ $MONGODB_PW ]]; then
  MONGO+="--mongo-password $MONGODB_PW "
fi
if [[ $MONGODB_PORT ]]; then
  MONGO+="--mongo-port $MONGODB_PORT "
fi
if [[ $MONGODB_HOST ]]; then
  MONGO+="--mongo-host $MONGODB_HOST "
fi
if [[ $MONGODB_URI ]]; then
  MONGO+="--mongo-uri $MONGODB_URI "
fi

# SQL DB Flags
SQLDB=""
if [[ $DATABASE_USER ]]; then
  SQLDB+="--db-username $DATABASE_USER "
fi
if [[ $DATABASE_PW ]]; then
  SQLDB+="--db-password $DATABASE_PW "
fi
if [[ $DATABASE_CONN ]]; then
  SQLDB+="--db-conn-str $DATABASE_CONN "
fi
if [[ $DATABASE_DRIVER ]]; then
  SQLDB+="--db-driver $DATABASE_DRIVER "
fi

# SPIDA Config (Includes SAML and E-mail Configuration)
SPIDA=""
if [[ $SERVER_ROOT ]];then
  SPIDA+="--server-root $SERVER_ROOT "
fi
if [[ $APPLICATION_DIRECTORY ]];then
  SPIDA+="--backupdir $APPLICATION_DIRECTORY "
else
  echo "Application directory MUST be set!"
fi
if [[ $SAML_ALIAS ]];then
  SPIDA+="--saml-alias $SAML_ALIAS "
fi
if [[ $SAML_PW ]];then
  SPIDA+="--saml-password $SAML_PW "
fi
if [[ $EMAIL_HOST ]];then
  SPIDA+="--email-host $EMAIL_HOST "
fi
if [[ $EMAIL_PORT ]];then
  SPIDA+="--email-port $EMAIL_PORT "
fi

# Admin Conf
ADMIN=""
if [[ $ADMIN_USER ]];then
  ADMIN+="--admin-user-email $ADMIN_USER "
fi
if [[ $ADMIN_PW ]];then
  ADMIN+="--admin-user-password $ADMIN_PW "
fi
if [[ $ADMIN_API_TOKEN ]];then
  ADMIN+="--admin-api-token $ADMIN_API_TOKEN "
fi

# Misc Conf
MISC=""
if [[ $TCAT_JAVA_MAX_MEM ]];then
  MISC+="--tomcat-memory $TCAT_JAVA_MAX_MEM "
fi

# Install Command
./genericInstall.sh $CONTAINERS $TAGS $MONGO $SQLDB $SPIDA $ADMIN $MISC
