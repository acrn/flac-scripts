#!/bin/bash

MUST_BE=root
DMA_EXEC=/usr/sbin/minidlna
RM_THESE=(
    "/var/minidlna/files.db"
    "/var/minidlna/art_cache"
    "/var/minidlna/minidlna.log"
)

if [ $(whoami) != $MUST_BE ]
then
    echo "must be $MUST_BE"
    exit 1
fi

DMA_PID=$(ps ax | awk -v "dmex=$DMA_EXEC" '($0 ~ dmex){print $1;exit;}')

kill $DMA_PID

sleep 5
for f in ${RM_THESE[@]}
do
    rm -r "$f"
done

$DMA_EXEC
