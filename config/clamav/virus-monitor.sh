#!/bin/bash

########################################################################################################################
# I wish I could use VirusEvent in the config to trigger a script when a virus is found but apparently it's disabled
# https://bbs.archlinux.org/viewtopic.php?id=237489
# https://github.com/Cisco-Talos/clamav-devel/blob/dev/0.100/clamd/onaccess_fan.c#L85
########################################################################################################################

########################################################################################################################
# So instead we are tailing logs to get the file paths found.
# Example log line
# Mon Nov  5 17:19:53 2018 -> ScanOnAccess: /home/jeremy/searchme/test1.txt: Eicar-Test-Signature(69630e4574ec6798239b091cda43dca0:69) FOUND
########################################################################################################################

LOG_FILE=/var/log/clamav/clamav.log
tail -F $LOG_FILE | while read LOG_LINE
do
    if [[ "${LOG_LINE}" == *"FOUND" ]]; then
        BAD_FILE=$(echo "$LOG_LINE" | sed 's/\(.*\) -> \(.*\):\(.*\)\((.*\):\(.*\) FOUND/\2/')
        VIRUS_TYPE=$(echo "$LOG_LINE" | sed 's/\(.*\) -> \(.*\):\(.*\)\((.*\):\(.*\) FOUND/\3/')

        if [ -e "$BAD_FILE" ]; then
            echo "BAD_FILE: $BAD_FILE"
            BAD_FILE_DIR=$(dirname "$BAD_FILE")
            BAD_FILE_BASE=$(basename "$BAD_FILE")
            pushd "$BAD_FILE_DIR"

                #setup git repo if it wan't one
                if [ ! -d "$BAD_FILE_DIR/.git" ]; then
                    git init
                fi

                git add .

                #commit any last changes
                if [ -n "$(git status --porcelain)" ]; then
                    git commit -am "last update before contents replaced"
                fi

                #replace the contents of the file and log it
                echo "This file has been marked as a potential virus: $VIRUS_TYPE.  We have stored a copy of the original file." > "$BAD_FILE"
                git commit -am "replaced contents of $BAD_FILE_BASE with notification of potential virus"
                echo "$0 replaced contents of $BAD_FILE with notification of potential virus" >> "$LOG_FILE"
            popd

        fi
    fi
done

