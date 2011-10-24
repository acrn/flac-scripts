#!/bin/bash

MP3DIR=/local/mp3 #TODO: make this an option

for a in "${@}"
do
    artist=$(metaflac --show-tag=ARTIST "$a" | sed 's/^.\+=//g')
    album=$(metaflac --show-tag=ALBUM "$a" | sed 's/^.\+=//g')
    title=$(metaflac --show-tag=TITLE "$a" | sed 's/^.\+=//g')
    tracknumber=$(metaflac --show-tag=TRACKNUMBER "$a" \
        | sed   -e 's/^.\+=//g' \
                -e 's/\/.*$//g')
    relativetargetdir=$(echo "$artist-$album" \
        | sed   -e 's/[ \t]/_/g' \
                -e 's/./\l&/g')
    relativetargetfile=$relativetargetdir/$(echo "$tracknumber-$title.mp3" \
        | sed   -e 's/[ \t]/_/g' \
                -e 's/./\l&/g')
    targetdir="$MP3DIR/$relativetargetdir"
    targetfile="$MP3DIR/$relativetargetfile"
    mkdir -p "$targetdir"
    flac -cd "$a" \
        | lame -V0 \
         --tt "$title" \
         --tn "$tracknumber" \
         --ta "$artist" \
         --tl "$album" \
         --add-id3v2 \
         - "$targetfile"
done
