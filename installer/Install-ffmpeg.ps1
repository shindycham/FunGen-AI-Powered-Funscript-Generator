# Import the function (adjust the path according to your setup)
$scriptPath = "./functions/private/Install-WinUtilProgramWinget.ps1"
if (Test-Path $scriptPath) {
    . $scriptPath
} else {
    Write-Host "Error: The script $scriptPath does not exist." -ForegroundColor Red
    exit 1
}

# Set up Information stream to be visible
$InformationPreference = "Continue"

Write-Host "Starting FFmpeg installation..." -ForegroundColor Cyan

try {
    # Test the function with verbose output
    Write-Host "Attempting to run Install-WinUtilProgramWinget for FFmpeg..." -ForegroundColor Cyan
    Install-WinUtilProgramWinget -Action "Install" -Programs @("Gyan.FFmpeg")

    # Verify FFmpeg is working
    if (Get-Command ffmpeg -ErrorAction SilentlyContinue) {
        Write-Host "Success! FFmpeg is installed and accessible." -ForegroundColor Green

        # Display FFmpeg version (clean output)
        Write-Host "FFmpeg version:" -ForegroundColor Cyan
        $FFmpegVersion = ffmpeg -version

        # Optionally, you can capture just the version line
        $FFmpegVersion | Select-String -Pattern "ffmpeg version" | ForEach-Object { $_.Line }
    } else {
        Write-Host "Warning: FFmpeg is installed but not accessible in the current session. You may need to restart your terminal." -ForegroundColor Yellow
    }
} catch {
    Write-Host "Error occurred during testing: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Stack Trace:" -ForegroundColor Red
    $_.ScriptStackTrace
}