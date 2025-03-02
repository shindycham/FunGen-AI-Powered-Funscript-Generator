# .\installer\Download-model.ps1

param (
    [string]$DownloadURL,
    [string]$SavePath
)

# Import the Invoke-GoFileDownload function
. .\functions\private\Invoke-GoFileDownload.ps1

# Call the Invoke-GoFileDownload function with the passed parameters
Write-Host "modelllll:" $DownloadURL $SavePath -ForegroundColor Cyan
Invoke-GoFileDownload -URL $DownloadURL -LiteralPath $SavePath
