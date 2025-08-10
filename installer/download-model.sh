#!/bin/bash

DOWNLOAD_URL="$1"
SAVE_PATH="$2"

echo "modelllll: $DOWNLOAD_URL $SAVE_PATH"

curl -L "$DOWNLOAD_URL" -o "$SAVE_PATH"
