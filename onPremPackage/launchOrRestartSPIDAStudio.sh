#!/bin/sh
set -e
########################
# SPIDAStudio Launcher #
########################

#This section of code is to avoid the error described here:
# https://stackoverflow.com/questions/57796839/docker-compose-error-while-loading-shared-libraries-libz-so-1-failed-to-map-s
mkdir -p $HOME/tmp
export TMPDIR=$HOME/tmp

# This utility is used to launch or restart a SPIDAStudio Instance
echo "Stopping any running docker containers..."
docker-compose -f docker-compose.yml down
echo "Removing old docker containers..."
docker-compose -f docker-compose.yml rm --force
echo "Starting new docker containers..."
docker-compose -f docker-compose.yml up -d
echo "Removing old docker images"
docker system prune --all --force