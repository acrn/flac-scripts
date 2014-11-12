#!/bin/bash

MP3DIR=/home/anders/tmp/mp3 #TODO: make this an option

for FLACFILE in "${@}"
do
    # csv the tags, pass non-ascii characters as variables
    # I'm guessing most of this transliteration stuff, it's probably wrong
    csv=$(metaflac --export-tags-to=- "$FLACFILE" | awk -F "=" '
    {
        gsub(/;/, "_", $2);
        tag[toupper($1)] = $2;
        # tolower("ABCÅÄÖ") -> "abcÅÄÖ", bug?

        value = $2
        # gsub(/[Öö]/, "o", "Öström") -> "oostroom", bug?
        # swedish
        gsub("Å", "A", value);
        gsub("å", "a", value);
        gsub("Ä", "A", value);
        gsub("ä", "a", value);
        gsub("Ö", "O", value);
        gsub("ö", "o", value);
        # icelandic
        gsub("Á", "A", value);
        gsub("á", "a", value);
        gsub("Ð", "TH", value);
        gsub("ð", "th", value);
        gsub("É", "E", value);
        gsub("é", "e", value);
        gsub("Í", "I", value);
        gsub("í", "i", value);
        gsub("Ó", "O", value);
        gsub("ó", "o", value);
        gsub("Ú", "U", value);
        gsub("ú", "u", value);
        gsub("Ý", "Y", value);
        gsub("ý", "y", value);
        gsub("Æ", "AE", value);
        gsub("æ", "ae", value);
        gsub("Þ", "TH", value);
        gsub("þ", "th", value);

        value = tolower(value);
        gsub(/[\/ ()]/, "_", value);

        safe_tag[toupper($1)] = value;
    }
    END {
    gsub(/\/.*/, "", safe_tag["TRACKNUMBER"]);
    #     1 ;   2 ;      3 ;   4 ;     5 ;      6
    # artist;album;tracknum;title;dirname;filename
    printf("%s;%s;%.2i;%s;%s-%s;%.2i-%s.mp3\n",
        tag["ARTIST"],
        tag["ALBUM"],
        safe_tag["TRACKNUMBER"],
        tag["TITLE"],
        safe_tag["ARTIST"],
        safe_tag["ALBUM"],
        safe_tag["TRACKNUMBER"],
        safe_tag["TITLE"]);
    }')

    for idx in {1..6}
    do
        value=$(echo $csv | cut -d ";" -f $idx)
        case $idx in
            1) ARTIST=$value;;
            2) ALBUM=$value;;
            3) TRACKNUMBER=$value;;
            4) TITLE=$value;;
            5) FOLDERNAME=$value;;
            6) FILENAME=$value;;
        esac
    done
    mkdir -v "$MP3DIR/$FOLDERNAME"
    flac -cd "$FLACFILE" \
        | lame -V0 \
         --tt "$TITLE" \
         --tn "$TRACKNUMBER" \
         --ta "$ARTIST" \
         --tl "$ALBUM" \
         --add-id3v2 \
         - "$MP3DIR/$FOLDERNAME/$FILENAME"
done
