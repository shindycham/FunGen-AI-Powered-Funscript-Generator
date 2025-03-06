@echo off
REM %~dp0 means current dir, we use \..\.. to move up two directories to the root of the project
REM you can replace this to the hardcoded path to your directory to make the bat file work from anywhere
cd /d "%~dp0\..\.."

REM Sets the path to your conda activation script and activate the environment.
set "CONDA_PATH=C:\Users\%USERNAME%\miniconda3\Scripts\activate.bat"
if not exist "%CONDA_PATH%" (
    echo Conda not found at %CONDA_PATH%. Please check your installation.
    pause
    exit /b 1
)
REM Activate the conda environment
call "%CONDA_PATH%" VRFunAIGen

REM Run the CLI command. Your path should look something like this: "C:\my-movie.mp4"
python -m script_generator.cli.generate_funscript_single "X:\VR\Movies No Script\DarkroomVR\Nikki Hill\v.0.2.0_FunGen-12s-pov-1.1.0.engine.3080_DarkroomVR - 2022-02-04 - Daddy's Good Girl [WEBDL-3630].mp4"

pause