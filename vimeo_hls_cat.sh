#!/usr/bin/env

# A ridiculous vimeo hls downloader

# time MODE=list bash ./vimeo_hls_cat.sh $(curl -s 'https://player.vimeo.com/video/181125561/config' | jq -r .request.files.hls.url)\
#   | head -3 | tail -1 | JOBS=40 MODE=cat xargs bash ./vimeo_hls_cat.sh \
#   | MODE=conv xargs -I{} bash ./vimeo_hls_cat.sh {} ./result$(date +%s)

MODE_LIST="list"
MODE_CAT="cat"
MODE_CONV="conv"

if [ -z "$MODE" ]
then
    echo "Provide a MODE env variable: $MODE_LIST, cat"
    echo -e "\tlist - will get .m3u8 urls from a playlist"
    echo -e "\tcat - will get a playlist and cat the .ts files in parallel"
    echo -e "\tconv - packages the mpegts as mp4 \$1 is the input, \$2 is the output file basename (.mp4 will be added)"
    exit 1
fi

if [ "$MODE" == "$MODE_LIST" ]
then
    manifest_url="$1"
    if [ -z "$manifest_url" ]
    then
        echo "Provide a manifest url"
        exit 1
    fi

    master="$(curl -s "$manifest_url")"
    for playlist in $(echo "$master" | grep '.m3u8$')
    do
        echo "$(dirname "$manifest_url")/$playlist"
    done
fi

if [ "$MODE" == "$MODE_CAT" ]
then
    hash parallel 2>/dev/null || { echo "gnu parallel is required"; exit 1; }

    playlist_url="$1"
    playlist=$(curl -s "$playlist_url")

    tmp=$(mktemp)
    echo "$playlist" | grep '.ts$' | parallel\
        -k -j"$JOBS" --progress curl -s $(dirname "$playlist_url")/{} >>"$tmp"

    echo "$tmp"
fi

if [ "$MODE" == "$MODE_CONV" ]
then
    ffmpeg -i "$1" -c:v copy -c:a copy -strict -2 -movflags +faststart -bsf:a aac_adtstoasc "$2.mp4"
fi
