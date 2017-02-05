## vimeo hls downloader

An experiment script conceived to learn more about gnu parallel.

Given a `MODE` env variable the script can perform a few tasks.

#### list

```bash
MODE=list bash ./vimeo_hls_cat.sh $(curl -s 'https://player.vimeo.com/video/181125561/config' | jq -r '.request.files.hls.cdns | map(.url) | .[]' | shuf | head -1)
```

Will list the various `.m3u8` profile playlists available (lowest quality first)

#### cat

Uses [gnu parallel](https://www.gnu.org/software/parallel/) with curl to download each segment and cat it to a file created by `mktemp`.
Output is the tmp file name.

> A `PROFILE_PLAYLIST_URL` can be obtained using the `list` option first

```bash
JOBS=40 MODE=cat bash ./vimeo_hls_cat.sh PROFILE_PLAYLIST_URL
```

#### conv

Does a dumb copy of the `mpegts` to a `.mp4` container

> .mp4 should be omitted from 2nd arg

```bash
MODE=conv bash ./vimeo_hls_cat.sh TEMP_FILE ./result$(date +%s)
```

### Example of everything in unison

```bash
MODE=list bash ./vimeo_hls_cat.sh $(curl -s 'https://player.vimeo.com/video/181125561/config' | jq -r '.request.files.hls.cdns | map(.url) | .[]' | shuf | head -1) | head -1 | JOBS=40 MODE=cat xargs bash ./vimeo_hls_cat.sh | MODE=conv xargs -I{} bash ./vimeo_hls_cat.sh {} ./result$(date +%s)
```

> Get hls config dynamically from player, parses out hls url with jq, takes lowest quality playlist url (`head -1`), uses it as arg to `cat` mode, uses temp file result as arg to `conv` mode.
