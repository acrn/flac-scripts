#!/bin/bash

MP3DIR=/local/mp3 #TODO: make this an option

for FLACFILE in "${@}"
do
    TAGS=$(metaflac --export-tags-to=- "$FLACFILE")
    ARTIST=$(echo "$TAGS" | awk -F "=" 'toupper($1) ~ /^ARTIST$/{print $2;}')
    ALBUM=$( echo "$TAGS" | awk -F "=" 'toupper($1) ~ /^ALBUM$/{ print $2;}')
    TITLE=$( echo "$TAGS" | awk -F "=" 'toupper($1) ~ /^TITLE$/{ print $2;}')
    TRACKNUMBER=$(echo "$TAGS" | awk -F "=" '
        toupper($1) ~ /^TRACKNUMBER$/{
            sub("/.*", "", $2);
            print $2;}')
    RELATIVETARGETDIR=$(echo "$ARTIST-$ALBUM" \
        | sed   -e 's/[ \t]/_/g' \
                -e 's/./\l&/g')
    RELATIVETARGETFILE=$RELATIVETARGETDIR/$(echo "$TRACKNUMBER-$TITLE.mp3" \
        | sed   -e 's/[ \t]/_/g' \
                -e 's/./\l&/g')
    TARGETDIR="$MP3DIR/$RELATIVETARGETDIR"
    TARGETFILE="$MP3DIR/$RELATIVETARGETFILE"
    mkdir -p "$TARGETDIR"
    flac -cd "$FLACFILE" \
        | lame -V0 \
         --tt "$TITLE" \
         --tn "$TRACKNUMBER" \
         --ta "$ARTIST" \
         --tl "$ALBUM" \
         --add-id3v2 \
         - "$TARGETFILE"
done
