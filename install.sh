#!/bin/bash

set -e
set -u
set -o pipefail

################################################################################
# Make sure this is being run as root (administrator)
################################################################################

if [[ $EUID -ne 0 ]]; then
    echo "Administrative permissions required. Please run as root (e.g., with sudo)."
    exit 1
fi

################################################################################
# Administrator check completed. Continuing...
################################################################################

# Get the directory where the script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="${SCRIPT_DIR}/logs"

# Ensure the 'logs' directory exists
mkdir -p "$LOG_DIR"
echo "Log files will be saved in: $LOG_DIR"

# Get the home directory of the current user
HOME_DIR="$HOME"

# Define repo folder
REPO_FOLDER="$SCRIPT_DIR"

# Create the full path to where the repository will be cloned
CLONE_PATH="$REPO_FOLDER"
BATCH_FILE="${CLONE_PATH}/Start_linux.sh"
DESKTOP_FILE="${HOME_DIR}/Desktop/FunGen.desktop"
ICON_PATH="${CLONE_PATH}/resources/icon.ico"

# Clear any existing log files
rm -rf "${LOG_DIR:?}"/*

cd "$SCRIPT_DIR"

################################################################################
# Install/Update Winget alternative (skip, not applicable for Linux)
################################################################################
# On Linux, use system package managers (apt, yum, dnf, pacman, etc.)

################################################################################
# Install/Update Miniconda
################################################################################

if ! command -v conda &> /dev/null; then
    echo "Miniconda not found. Installing Miniconda..."
    MINICONDA_SCRIPT="Miniconda3-latest-Linux-x86_64.sh"
    wget https://repo.anaconda.com/miniconda/$MINICONDA_SCRIPT -O "$LOG_DIR/$MINICONDA_SCRIPT"
    bash "$LOG_DIR/$MINICONDA_SCRIPT" -b -p "$HOME/miniconda3"
    export PATH="$HOME/miniconda3/bin:$PATH"
    source "$HOME/miniconda3/etc/profile.d/conda.sh"
else
    echo "Miniconda already installed."
    export PATH="$HOME/miniconda3/bin:$PATH"
    source "$HOME/miniconda3/etc/profile.d/conda.sh"
fi

################################################################################
# Install/Update ffmpeg
################################################################################
if ! command -v ffmpeg &> /dev/null; then
    echo "ffmpeg not found. Installing..."
    if command -v apt-get &> /dev/null; then
        apt-get update && apt-get install -y ffmpeg
    elif command -v dnf &> /dev/null; then
        dnf install -y ffmpeg
    elif command -v pacman &> /dev/null; then
        pacman -Sy ffmpeg --noconfirm
    else
        echo "Please install ffmpeg manually."
        exit 1
    fi
else
    echo "ffmpeg already installed."
fi

################################################################################
# Miniconda environment initialization
################################################################################

source "$HOME/miniconda3/etc/profile.d/conda.sh"
conda activate base

if ! conda info --envs | grep -q "VRFunAIGen"; then
    echo "Environment 'VRFunAIGen' not found. Creating it..."
    conda create -n VRFunAIGen python=3.11 -y
else
    echo "Environment 'VRFunAIGen' already exists."
fi

conda activate VRFunAIGen

################################################################################
# Install python requirements
################################################################################

if [[ -f core.requirements.txt ]]; then
    echo "Installing packages from core.requirements.txt..."
    pip install -r core.requirements.txt | tee "${LOG_DIR}/core_requirements_log.txt"
else
    echo "core.requirements.txt not found in the current directory."
fi

################################################################################
# Check if NVIDIA GPU is available
################################################################################

if command -v nvidia-smi &> /dev/null && nvidia-smi > /dev/null 2>&1; then
    CUDA_AVAILABLE=true
    echo "NVIDIA GPU detected. Installing CUDA dependencies..."
else
    CUDA_AVAILABLE=false
    echo "No NVIDIA GPU detected. Installing CPU dependencies..."
    if [[ -f cpu.requirements.txt ]]; then
        pip install -r cpu.requirements.txt | tee "${LOG_DIR}/cpu_requirements_log.txt"
        echo "CPU requirements installation completed."
    else
        echo "cpu.requirements.txt not found."
    fi
fi

if [ "$CUDA_AVAILABLE" = true ]; then
    echo "Installing CUDA requirements, please wait..."
    if [[ -f cuda.requirements.txt ]]; then
        pip install -r cuda.requirements.txt | tee "${LOG_DIR}/cuda_requirements_log.txt"
        pip install tensorrt | tee "${LOG_DIR}/tensorrt_requirements_log.txt"
    else
        echo "cuda.requirements.txt not found in the current directory."
    fi
fi

################################################################################
# Download models
################################################################################

MODELS_DIR="${CLONE_PATH}/models"
mkdir -p "$MODELS_DIR"

echo
echo "======================================================"
echo "Model Download Section"
echo "======================================================"

echo "Choose the type of models to download:"
echo "Currently the choice is irrelevant. It downloads all models no matter what you pick."
echo "1 - Slower but more powerful models"
echo "2 - Faster but less accurate models"
echo "3 - All models"
read -p "Enter your choice (1/2/3): " choice

echo "Processing selection..."

download_model() {
    local url="$1"
    local filename="$2"
    local arch="$3"
    local type="$4"

    # Logic for choice and CUDA availability
    if [[ "$choice" == "1" && "$type" == "s" ]]; then
        if [[ "$CUDA_AVAILABLE" == true && "$arch" == "pt" ]]; then
            :
        elif [[ "$CUDA_AVAILABLE" == false && "$arch" == "onnx" ]]; then
            :
        else
            return
        fi
    elif [[ "$choice" == "2" && "$type" == "n" ]]; then
        if [[ "$CUDA_AVAILABLE" == true && "$arch" == "pt" ]]; then
            :
        elif [[ "$CUDA_AVAILABLE" == false && "$arch" == "onnx" ]]; then
            :
        else
            return
        fi
    elif [[ "$choice" == "3" ]]; then
        :
    else
        return
    fi

    # Download file
    echo "Downloading $filename..."
    python gofile-downloader/gofile-downloader.py "$url" > "${LOG_DIR}/model_download.txt" 2>&1
    if [[ $? -ne 0 ]]; then
        echo "ERROR: Failed to download $filename"
    else
        echo "Download of $filename complete"
    fi
}

download_model "https://gofile.io/d/wpo23V" "FunGen-12s-pov-1.1.0.onnx" "onnx" "s"
download_model "https://gofile.io/d/wpo23V" "FunGen-12n-pov-1.1.0.onnx" "onnx" "n"
download_model "https://gofile.io/d/wpo23V" "FunGen-12s-pov-1.1.0.pt" "pt" "s"
download_model "https://gofile.io/d/wpo23V" "FunGen-12n-pov-1.1.0.pt" "pt" "n"

echo "Model downloads complete. Files saved in $MODELS_DIR"

################################################################################
# Create Desktop Shortcut (Linux)
################################################################################

echo "Creating Desktop Shortcut..."

cat <<EOF > "$DESKTOP_FILE"
[Desktop Entry]
Type=Application
Name=FunGen
Exec=bash "$BATCH_FILE"
Icon=$ICON_PATH
Terminal=true
EOF
chmod +x "$DESKTOP_FILE"

################################################################################
# Final message
################################################################################

echo "======================================================"
echo "Installation complete! You can now close this window."
echo "======================================================"

conda list > "${LOG_DIR}/conda_list.txt" 2>&1
echo "Press any key to exit..."
read -n 1 -s
conda deactivate
exit 0
