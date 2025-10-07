#!/bin/bash

# Configuration
CONFIG_FILE="playlists.conf"
BASE_DIR="$HOME/Music"
RETRY_COUNT=1
BITRATE="192k"
SPOTIFY_PREFIX="https://open.spotify.com/playlist/"

# Go back from music-setup folder
cd ..
echo "Working from directory: $PWD"

# Check config file
if [[ ! -f "$CONFIG_FILE" ]]; then
    echo "[-] Configuration file '$CONFIG_FILE' not found!"
    exit 1
fi

# Sync playlists
while read -r line; do
    [[ -z "$line" || "$line" =~ ^# ]] && continue

    folder="${line%%=*}"

    target_dir="$BASE_DIR/$folder"
    mkdir -p "$target_dir"
    cd "$target_dir" || continue

    echo "[+] Generating m3u8 file for '$target_dir'"

    playlist="$folder.m3u8"
    echo "#EXTM3U" > "$playlist"

    for f in "$target_dir"/*.mp3; do
        [ -e "$f" ] || continue
        duration=$(ffprobe -v error -show_entries format=duration \
            -of default=noprint_wrappers=1:nokey=1 "$f" | cut -d'.' -f1)
        title=$(basename "$f" .mp3)
        echo "#EXTINF:$duration,$title" >> "$playlist"
        echo "$(basename "$f")" >> "$playlist"
    done

    echo "#EXT-X-ENDLIST" >> "$playlist"
    echo "Created $playlist"

    echo
done < "$CONFIG_FILE"
