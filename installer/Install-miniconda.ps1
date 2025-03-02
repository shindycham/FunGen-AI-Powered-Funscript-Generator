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

Write-Host "Starting Miniconda3 installation..." -ForegroundColor Cyan

try {
    # Test the function with verbose output
    Write-Host "Attempting to run Install-WinUtilProgramWinget..." -ForegroundColor Cyan
    Install-WinUtilProgramWinget -Action "Install" -Programs @("Anaconda.Miniconda3")

    # Verify Miniconda is working
    $minicondaPath = "$env:USERPROFILE\miniconda3\Scripts\activate.bat"
    if (Test-Path $minicondaPath) {
        & $minicondaPath base
    Write-Host $minicondaPath -ForegroundColor Magenta
    exit

        if (Get-Command conda -ErrorAction SilentlyContinue) {
            Write-Host "Success! Miniconda is working. Conda is available." -ForegroundColor Green

            # Display Miniconda version
            Write-Host "Miniconda version:" -ForegroundColor Cyan
            conda --version

            # Add Conda to PATH if it isn't automatically added
            $condaPath = "$env:USERPROFILE\miniconda3\Scripts"
            $currentPath = [System.Environment]::GetEnvironmentVariable('PATH', 'User')
            
            # Check if Conda is already in the PATH
            if ($currentPath -notlike "*$condaPath*") {
                # Append Conda path to the user's PATH if it's not already there
                $newPath = "$currentPath;$condaPath"
                [System.Environment]::SetEnvironmentVariable('PATH', $newPath, 'User')
                Write-Host "Conda path added to the system PATH variable." -ForegroundColor Green

                # Reload the environment variables for the current session
                $env:PATH = [System.Environment]::GetEnvironmentVariable('PATH', 'User')
                Write-Host "Environment variables reloaded for the current session." -ForegroundColor Green

                # Recheck the command again after reloading the environment variables
                if (Get-Command conda -ErrorAction SilentlyContinue) {
                    Write-Host "Conda is now available in the current session!" -ForegroundColor Green
                } else {
                    Write-Host "Warning: Conda is still not accessible in the current session." -ForegroundColor Yellow
                }
            } else {
                Write-Host "Conda path is already in the PATH variable." -ForegroundColor Yellow
            }
        } else {
            Write-Host "Warning: Miniconda is installed but not accessible in the current session. You may need to restart your terminal." -ForegroundColor Yellow
        }
    } else {
        Write-Host "Error: Miniconda installation failed. 'activate.bat' not found." -ForegroundColor Red
    }
} catch {
    Write-Host "Error occurred during testing: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Stack Trace:" -ForegroundColor Red
    $_.ScriptStackTrace
}
