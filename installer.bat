@echo off
SETLOCAL EnableDelayedExpansion

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
@REM Make sure this is being ran as an administrator
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::


@echo off
goto check_Permissions

:check_Permissions
echo Administrative permissions required. Detecting permissions...
net session >nul 2>&1
if %errorLevel% == 0 (
    echo Success: Administrative permissions confirmed.
) else (
    echo Failure: Current permissions inadequate.
    pause >nul
    exit /B 1
)

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
@REM Administrator check completed. Continuing...
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

:: Get the directory where the batch file is located
set "BATCH_DIR=%~dp0logs\"
:: Ensure the 'logs' directory exists (optional)
if not exist "%BATCH_DIR%" mkdir "%BATCH_DIR%"
echo Log files will be saved in: %BATCH_DIR%

:: Get the home directory of the current user
set "homeDir=%USERPROFILE%"

:: Define the target folder name
set "repoFolder=%~dp0"

:: Create the full path to where the repository will be cloned
set "clonePath=%repoFolder%"
set "batchFile=%clonePath%\Start windows.bat"
set "desktop=%USERPROFILE%\Desktop\FunGen.lnk"
set "iconPath=%clonePath%\resources\icon.ico"

:: Clear any existing log files
:: Delete all files in the directory
del /q /f /s "%BATCH_DIR%\*"

:: Delete all subdirectories
for /d %%x in ("%BATCH_DIR%\*") do rmdir /s /q "%%x"

CD /d "%~dp0"

:: Install/Update winget
powershell -ExecutionPolicy Bypass -File .\installer\Test-WingetInstall.ps1

:: Install/Update minconda
powershell -ExecutionPolicy Bypass -File .\installer\Install-miniconda.ps1

:: Install/Update ffmpeg
powershell -ExecutionPolicy Bypass -File ".\installer\Install-ffmpeg.ps1"

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
@REM All external dependencies have been installed. Moving on to initializing miniconda environment...
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

:: Activate the base environment first
call C:\Users\%USERNAME%\miniconda3\Scripts\activate.bat base

:: Create the new environment if it doesn't already exist
conda info --envs | findstr /C:"VRFunAIGen"
if %errorlevel% neq 0 (
    echo Environment "VRFunAIGen" not found. Creating it...
    conda create -n VRFunAIGen python=3.11 -y
) else (
    echo Environment "VRFunAIGen" already exists.
)

:: Activate the specific conda environment
call C:\Users\%USERNAME%\miniconda3\Scripts\activate.bat VRFunAIGen

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
@REM Miniconda environment initialized. Installing python requirements...
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

:: Ensure the working directory contains core.requirements.txt
if exist core.requirements.txt (
    echo Installing packages from core.requirements.txt...
    powershell -Command "pip install -r core.requirements.txt | Tee-Object -FilePath '%BATCH_DIR%core_requirements_log.txt'"
) else (
    echo core.requirements.txt not found in the current directory.
)
:: Check if NVIDIA GPU is available
nvidia-smi > nul 2>&1

IF %ERRORLEVEL% == 0 (
    set "cuda_available=true"
    echo "NVIDIA GPU detected. Installing CUDA dependencies..."
) ELSE (
    :: NVIDIA GPU is not available
    set "cuda_available=false"
    echo "No NVIDIA GPU detected. Installing CPU dependencies..."
    :: Install CPU-specific dependencies with logging
    powershell -Command "conda run -n VRFunAIGen pip install -r cpu.requirements.txt" > "%BATCH_DIR%\cpu_requirements_log.txt" 2>&1
    echo "CPU requirements installation completed."
    goto models :: Skip installing cuda requirements.
)

:: Install CUDA-specific dependencies with logging
echo Installing CUDA requirements, please wait...
:: Ensure the working directory contains cuda.requirements.txt
if exist cuda.requirements.txt (
    echo Installing packages from cuda.requirements.txt...
    powershell -Command "pip install -r cuda.requirements.txt | Tee-Object -FilePath '%BATCH_DIR%\cuda_requirements_log.txt'"
    powershell -Command "pip install tensorrt | Tee-Object -FilePath '%BATCH_DIR%\tensorrt_requirements_log.txt'"
) else (
    echo cuda.requirements.txt not found in the current directory.
)

:models
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
@REM Python requirements installed. Download models...
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

:: Create models directory if it doesn't exist
set "modelsDir=%clonePath%models"
if not exist "%modelsDir%" mkdir "%modelsDir%"

:: Download models section
echo.
echo ======================================================
echo Model Download Section
echo ======================================================

:: Prompt user for model type
echo Choose the type of models to download:
echo 1 - Slower but more powerful models
echo 2 - Faster but less accurate models
echo 3 - All models
set /p choice="Enter your choice (1/2/3): "

:: Process user choice
echo Processing selection...

:: Define and process models directly
call :process_model "https://gofile.io/d/wpo23V" "FunGen-12s-pov-1.1.0.onnx" "onnx" "s"
call :process_model "https://gofile.io/d/wpo23V" "FunGen-12n-pov-1.1.0.onnx" "onnx" "n"
call :process_model "https://gofile.io/d/wpo23V" "FunGen-12s-pov-1.1.0.pt" "pt" "s"
call :process_model "https://gofile.io/d/wpo23V" "FunGen-12n-pov-1.1.0.pt" "pt" "n"

echo Model downloads complete Files saved in %modelsDir%

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
@REM Models downloaded. Creating Desktop Shortcut...
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

:: Create Desktop Shortcut
:instructions
powershell -Command "Write-Host 'Creating Desktop Shortcut' -ForegroundColor Green"
powershell -Command ^
    $desktop = '%desktop%'; ^
    $batchFile = '%batchFile%'; ^
    $iconPath = '%iconPath%'; ^
    $WshShell = New-Object -ComObject WScript.Shell; ^
    $Shortcut = $WshShell.CreateShortcut($desktop); ^
    $Shortcut.TargetPath = $batchFile; ^
    $Shortcut.IconLocation = $iconPath; ^
    $Shortcut.Save()

:: Final message
goto :endScript

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
@REM Helper functions
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

:: Process model based on user choice
:process_model
set "model_url=%~1"
set "model_filename=%~2"
set "model_arch=%~3"
set "model_type=%~4"

if "%choice%"=="1" (
    if "%model_type%"=="s" (
         if "%cuda_available%"=="true" (
             if "%model_arch%"=="pt" call :download_file "%model_url%" "%model_filename%"
         ) else (
             if "%model_arch%"=="onnx" call :download_file "%model_url%" "%model_filename%"
         )
    )
    goto :EOF
)

if "%choice%"=="2" (
    if "%model_type%"=="n" (
         if "%cuda_available%"=="true" (
             if "%model_arch%"=="pt" call :download_file "%model_url%" "%model_filename%"
         ) else (
             if "%model_arch%"=="onnx" call :download_file "%model_url%" "%model_filename%"
         )
    )
    goto :EOF
)

if "%choice%"=="3" (
    call :download_file "%model_url%" "%model_filename%"
)

goto :EOF

:: Function to download files
:download_file
set "url=%~1"
set "filename=%~2"

:: Check for empty URL
if "%url%"=="" (
    echo ERROR: Invalid URL for %filename%! Skipping...
    goto :EOF
)

:: Perform the download
echo Downloading %filename%...

:: Call the PowerShell script to download the model and pass the arguments
echo -DownloadURL %url% -SavePath %modelsDir%\%filename%



set GF_DOWNLOADDIR=%modelsDir%
python gofile-downloader\gofile-downloader.py %url%  > "%BATCH_DIR%\model_download.txt" 2>&1

powershell -Command "Write-Host 'Model download complete' -ForegroundColor Green;


:: Check for errors
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Failed to download %filename%
) else (
    echo Download of %filename% complete
)
goto :EOF

:errorHandler
echo.
echo ======================================================
echo ERROR: An issue occurred during installation.
echo Please check the error messages above.
echo Press any key to exit.
echo ======================================================
pause >nul
exit /b 1


:endScript
echo.
powershell -Command "Write-Host '======================================================' -ForegroundColor Green; Write-Host 'Installation complete! You can now close this window.' -ForegroundColor Green; Write-Host '======================================================' -ForegroundColor Green; Write-Host 'Setup is complete!' -ForegroundColor Green; Write-Host 'Double-click the shortcut on your Desktop called FunGen' -ForegroundColor Green; Write-Host 'It may take several minutes for the window to open initially' -ForegroundColor Green; Write-Host 'Join our Discord server for help and support https://discord.gg/WYkjMbtCZA' -ForegroundColor Green"
echo.
pause
:: List the installed packages in the environment
conda list > "%BATCH_DIR%\conda_list.txt" 2>&1
echo.
echo Press any key to exit...
::conda deactivate
pause >nul
exit /b 0