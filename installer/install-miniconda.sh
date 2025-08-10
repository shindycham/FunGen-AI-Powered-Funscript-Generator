#!/bin/bash

echo "Starting Miniconda3 installation..."

MINICONDA_SCRIPT="Miniconda3-latest-Linux-x86_64.sh"
wget https://repo.anaconda.com/miniconda/$MINICONDA_SCRIPT -O /tmp/$MINICONDA_SCRIPT

bash /tmp/$MINICONDA_SCRIPT -b -p "$HOME/miniconda3"

export PATH="$HOME/miniconda3/bin:$PATH"

if command -v conda >/dev/null 2>&1; then
    echo "Success! Miniconda is working. Conda is available."
    echo "Miniconda version:"
    conda --version
else
    echo "Error: Miniconda installation failed or conda is not accessible."
fi
