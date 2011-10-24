#!/bin/bash

MUST_BE=root
DMA_EXEC=/usr/sbin/minidlna
CONF_FILE=/etc/minidlna.conf
VAR_DIR=/var/minidlna
CONF_FILE_PATTERN=/etc/minidlna_%ENV%.conf
VAR_DIR_PATTERN=/var/minidlna_%ENV%

if [ $(whoami) != $MUST_BE ]
then
    echo "must be $MUST_BE"
    exit 1
fi

TARGET_CONF_FILE=$(echo "$CONF_FILE_PATTERN" | sed "s/%ENV%/$1/g")
TARGET_VAR_DIR=$(echo "$VAR_DIR_PATTERN" | sed "s/%ENV%/$1/g")

if [ ! -e "$TARGET_CONF_FILE" ]
then
    echo "$TARGET_CONF_FILE does not exist"
    exit -1
fi

if [ ! -e "$TARGET_VAR_DIR" ]
then
    echo "$TARGET_VAR_DIR does not exist"
    exit -1
fi

DMA_PID=$(ps -ef \
        | egrep "$DMA_EXEC$" \
        | head -n 1 \
        | sed   -e 's/^[^ ]*[ ]*//' \
                -e 's/[ ]\+.*$//')


kill "$DMA_PID"
sleep 5

if [ -h "$VAR_DIR" ]
then
    rm "$VAR_DIR"
fi

if [ -h "$CONF_FILE" ]
then
    rm "$CONF_FILE"
fi

ln -sf "$TARGET_VAR_DIR" "$VAR_DIR"
ln -sf "$TARGET_CONF_FILE" "$CONF_FILE"

"$DMA_EXEC"
