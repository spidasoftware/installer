#!/bin/bash

####################################################################################
# Vars
####################################################################################
dockerUsername=""
dockerPassword=""
dockerComposeFile=/etc/spida/docker-compose.yml

####################################################################################
# Parses Args
####################################################################################
function parseCommandLineArguments() {
  while [ $# -gt 0 ]
  do
      case "$1" in
          --composefile)  dockerComposeFile="$2"; shift;;

          *)
              echo >&2 \
              "usage: $0 [option value]
                Options:
                  --composefile       the location of the docker compose file (defaults to $dockerComposeFile)
              "
              exit 1;;
          *)  break;; # terminate while loop
      esac
      shift
  done
}

parseCommandLineArguments $@

echo "stopping docker containers..."
sudo docker-compose -f $dockerComposeFile stop
echo "removing old docker containers..."
sudo docker-compose -f $dockerComposeFile rm --force
echo "updating docker containers..."
sudo docker-compose -f $dockerComposeFile pull
echo "starting new docker containers..."
sudo docker-compose -f $dockerComposeFile up -d
echo "removing old docker images"
