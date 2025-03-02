# Source the function script
. "./functions/private/Install-miniconda.ps1"

# Call the function
Install-WinUtilProgramWinget -Action Install -Programs 'Anaconda.Miniconda3'
