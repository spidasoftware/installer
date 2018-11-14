#!/bin/bash

LAST_HASH=""

inotifywait -m -r -e close_write --format '%w%f' --exclude \.git /apps/spidamin/files/ | while read FILE_PATH 
do 
    if [ -f "$FILE_PATH" ]; then #check if file (not a dir)
        FILE_HASH=$(md5sum "$FILE_PATH")
        if [ "$FILE_HASH" != "$LAST_HASH" ];then #prevent infinite loop

            LAST_HASH="$FILE_HASH"

            clamdscan --no-summary "$FILE_PATH"
        fi
    fi
done
