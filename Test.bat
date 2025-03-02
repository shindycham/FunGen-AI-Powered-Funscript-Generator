@echo off
CD /d "%~dp0"
powershell -ExecutionPolicy Bypass -File ".\installer\Install-ffmpeg.ps1"
pause
