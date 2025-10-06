#!/bin/bash

# Configuration
CONFIG_FILE="playlists.conf"
BASE_DIR="$HOME/Music"
RETRY_COUNT=1
BITRATE="192k"
SPOTIFY_PREFIX="https://open.spotify.com/playlist/"

# Check if spotdl is installed
if ! command -v spotdl &> /dev/null; then
    echo "[-] spotdl is not installed. Exiting."
    exit 1
fi

# Check config file
if [[ ! -f "$CONFIG_FILE" ]]; then
    echo "[-] Configuration file '$CONFIG_FILE' not found!"
    exit 1
fi

# Sync playlists
while read -r line; do
    [[ -z "$line" || "$line" =~ ^# ]] && continue

    # sleep 10
    echo "[+] Starting sync iteration..."

    folder="${line%%=*}"
    playlist_id="${line#*=}"

    playlist_url="${SPOTIFY_PREFIX}${playlist_id}"

    target_dir="$BASE_DIR/$folder"
    mkdir -p "$target_dir"
    cd "$target_dir" || continue

    echo "[+] Syncing playlist '$playlist_url' into '$target_dir'"

    attempt=1
    while [[ $attempt -le $RETRY_COUNT ]]; do
        echo "[+] Attempt $attempt..."
        spotdl --m3u {list} --bitrate "$BITRATE" --save-file "$target_dir.spotdl" save "$playlist_url"
        exit_code=$?

        if [[ $exit_code -eq 0 ]]; then
            echo "[+] Success on attempt $attempt"
            break
        else
            echo "[-] Failed attempt $attempt"
            ((attempt++))
            sleep 2
        fi
    done

    if [[ $exit_code -ne 0 ]]; then
        echo "[-] Failed to sync playlist '$playlist_url' after $RETRY_COUNT attempts"
    fi

    echo
done < "$CONFIG_FILE"
