#!/bin/bash

echo "Starting FFmpeg installation..."

# Install ffmpeg (Ubuntu/Debian)
if command -v apt >/dev/null 2>&1; then
    sudo apt update
    sudo apt install -y ffmpeg
# Install ffmpeg (Fedora)
elif command -v dnf >/dev/null 2>&1; then
    sudo dnf install -y ffmpeg
# Install ffmpeg (Arch)
elif command -v pacman >/dev/null 2>&1; then
    sudo pacman -Sy ffmpeg
else
    echo "Unsupported package manager. Please install ffmpeg manually."
    exit 1
fi

if command -v ffmpeg >/dev/null 2>&1; then
    echo "Success! FFmpeg is installed and accessible."
    echo "FFmpeg version:"
    ffmpeg -version | grep "ffmpeg version"
else
    echo "Warning: FFmpeg installation failed or is not accessible in the current session."
fi
