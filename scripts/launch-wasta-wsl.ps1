# This script has 3 goals:
# - Start Wasta WSL.
# - Start genie systemd service on Wasta WSL.
# - Launch X Window for Wasta WSL.

# Check if Wasta WSL is already running.
$check = Test-Connection -ComputerName $env:computername-wsl -Quiet
If ($check -eq $false) {
    Write-Host "Booting up Wasta-20.04 now. Please be patient..."
}
While ($check -eq $false) {
    # Try to start Wasta WSL and genie systemd service.
    wsl --distribution 'Wasta-20.04' genie -i
    $check = $?
}

# Have to wait awhile, otherwise vcxsrv will fail to start.
Write-Host "Waiting for Wasta to come online..."
$check = Test-Connection -ComputerName $env:computername-wsl -Quiet
While ($check -eq $false) {
    $wait = 1
    Start-Sleep -Seconds $wait
    $check = Test-Connection -ComputerName $env:computername-wsl -Quiet
}

# Launch X Window for Wasta WSL.
& C:\'Program Files'\VcXsrv\vcxsrv.exe -ac -wgl -dpms -wr -query $env:computername-wsl
$check = $?

# Delete Wasta-20.04.tar to save disk space (but keep Wasta-20.04.tar.gz).
If ($check -eq $true) {
    Remove-Item "$env:APPDATA\Wasta-Linux\Wasta-20.04.tar" -ErrorAction 'SilentlyContinue'
}
