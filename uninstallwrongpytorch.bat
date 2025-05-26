@echo off

:: Set the path to your Miniconda installation
call "%USERPROFILE%\miniconda3\condabin\conda.bat" run -n VRFunAIGen pip uninstall -y torch torchvision
echo Edit the cuda.requirements.txt file and change the end of the first line from 121 to 128, then rerun the installer.bat.
echo Press any key to exit...
::conda deactivate
pause >nul
exit /b 0