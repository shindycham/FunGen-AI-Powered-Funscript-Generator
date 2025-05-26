@echo off
setlocal

rem Clear any previous values
set "GPU_NAME="

for /f "skip=1 tokens=*" %%i in ('wmic path win32_VideoController get name') do (
    rem Skip empty lines
    if not "%%i"=="" (
        echo GPU Detected: %%i
        rem Capture the first GPU only
        if not defined GPU_NAME (
            set "GPU_NAME=%%i"
        )
    )
)

echo First detected GPU: %GPU_NAME%
pause
