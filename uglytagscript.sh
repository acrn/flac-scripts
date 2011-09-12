#!/bin/bash

METAFLAC="metaflac"

SEDS=( )
RAWTAGS=( )
FILES=( )
GUESSTITLE=0
GUESSARTIST=0
GUESSALBUM=0
DEBUG=0
AUTONUM=0

USAGE="Just do it right!"

while getopts "ade:nr:lt" flag
do
    case $flag in
        a)
            GUESSARTIST=1;;
        d)
            DEBUG=1;;
        e)
            SEDS=( "${SEDS[@]}" "$OPTARG" );;
        n)
            AUTONUM=1;;
        r)
            RAWTAGS=( "${RAWTAGS[@]}" "$OPTARG" );;
        l)
            GUESSALBUM=1;;
        t)
            GUESSTITLE=1;;
    esac
done
FILES=( "${@:$OPTIND}" )

for f in "${FILES[@]}"
do
    READLINK=`readlink -f "$f"`
    DIRNAME=`dirname "$READLINK"`
    BASENAME=`basename "$READLINK"`
    BASEDIRNAME=`basename "$DIRNAME"`

    # Process all tags with sed, note that the tag names are included in the
    # calls to sed, so using the arguments "-e 's/ARTIST/bleh'" will ruin the
    # tags
    if [ "${#SEDS}" -gt 0 ]
    then
        TAGEXPORT=`$METAFLAC --export-tags-to=- "$f"`
        for s in "${SEDS[@]}"
        do
            TAGEXPORT=`echo "$TAGEXPORT" | sed -e "$s"`
        done
        `$METAFLAC --remove-all-tags "$f"`
        `echo "$TAGEXPORT" $METAFLAC --import-tags-from=- "$f"`
    fi

    # Add tags supplied in raw form to the arguments, if a tag with the same
    # name is already present it will be removed
    for r in "${RAWTAGS[@]}"
    do
        `$METAFLAC --remove-tag=$(echo "$r" | sed 's/=.*\$//') "$f"`
        `$METAFLAC --set-tag="$r" "$f"`
    done
    
    # Add an ARTIST tag based on the directory name of the file.
    if [ $GUESSARTIST -gt 0 ]
    then
        ARTISTGUESS=`echo $BASEDIRNAME | sed \
            -e 's/_/ /g' \
            -e 's/[ \t]*-.*$//' \
            -e 's/\(^\| \)./\U&/g'` #capitalize
        `$METAFLAC --remove-tag="ARTIST" "$f"`
        `$METAFLAC --set-tag="ARTIST=$ARTISTGUESS" "$f"`
    fi

    # Add an ALBUM tag based on the directory name of the file.
    if [ $GUESSALBUM -gt 0 ]
    then
        ALBUMGUESS=`echo $BASEDIRNAME | sed \
            -e 's/_/ /g' \
            -e 's/^.*-[ \t]*//' \
            -e 's/\(^\| \)./\U&/g'` #capitalize
        `$METAFLAC --remove-tag="ALBUM" "$f"`
        `$METAFLAC --set-tag="ALBUM=$ALBUMGUESS" "$f"`
    fi

    # Add a TITLE tag based on the name of the file.
    if [ $GUESSTITLE -gt 0 ]
    then
        TITLEGUESS=`echo $BASENAME | sed \
            -e 's/_/ /g' \
            -e 's/^[^a-zA-Z]*//' \
            -e 's/\..*$//' \
            -e 's/\(^\| \)./\U&/g'` #capitalize
        `$METAFLAC --remove-tag="TITLE" "$f"`
        `$METAFLAC --set-tag="TITLE=$TITLEGUESS" "$f"`
    fi
done

# Automatically set TRACKNUMBER based on all files given sorted lexically
if [ $AUTONUM -gt 0 ]
then
    for f1 in "${FILES[@]}"
    do
        INDEX=1
        for f2 in "${FILES[@]}"
        do
            if [ "$f1" \> "$f2" ]
            then
                INDEX=$(( $INDEX + 1 ))
            fi
        done
        `$METAFLAC --remove-tag="TOTALTRACKS" "$f1"`
        `$METAFLAC --set-tag="TOTALTRACKS=${#FILES[@]}" "$f1"`
        `$METAFLAC --remove-tag="TRACKNUMBER" "$f1"`
        `$METAFLAC --set-tag="TRACKNUMBER=$INDEX" "$f1"`
    done
fi

if [ $DEBUG -gt 0 ]
then
    for s in "${SEDS[@]}"
    do
        echo $s is a sed
    done

    for f in "${FILES[@]}"
    do
        echo $f is a file
    done

    for r in "${RAWTAGS[@]}"
    do
        echo $r is a raw tag
    done
fi
