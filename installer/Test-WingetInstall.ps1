# Import the function (adjust the path according to your setup)
$scriptPath = "./functions/private/Get-WinUtilWingetLatest.ps1"
if (Test-Path $scriptPath) {
    . $scriptPath
} else {
    Write-Host "Error: The script $scriptPath does not exist." -ForegroundColor Red
    exit 1
}

# Set up Information stream to be visible
$InformationPreference = "Continue"

Write-Host "Starting Winget installation test..." -ForegroundColor Cyan

try {
    # Test the function with verbose output
    Write-Host "Attempting to run Get-WinUtilWingetLatest..." -ForegroundColor Cyan
    Get-WinUtilWingetLatest -Verbose

    # Verify Winget is working
    if (Get-Command winget -ErrorAction SilentlyContinue) {
        Write-Host "Success! Winget is installed and accessible." -ForegroundColor Green

        # Display Winget version
        Write-Host "`nWinget version:" -ForegroundColor Cyan
        $wingetVersion = winget --version
        Write-Host $wingetVersion -ForegroundColor Cyan
    } else {
        Write-Host "Warning: Winget is installed but not accessible in the current session. You may need to restart your terminal." -ForegroundColor Yellow
    }
} catch {
    Write-Host "Error occurred during testing: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Stack Trace:" -ForegroundColor Red
    $_.ScriptStackTrace
}
