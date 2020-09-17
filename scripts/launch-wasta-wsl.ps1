# This script has 3 goals:
# - Start Wasta WSL.
# - Start genie systemd service on Wasta WSL.
# - Launch X Window for Wasta WSL.

# Check if Wasta WSL is already running.
Test-Connection -TartgetName "$env:computername-wsl" -ErrorAction 'SilentlyContinue'
$check = $?
If ($check -eq $false) {
    Write-Host "Booting up Wasta-20.04 now. Please be patient..."
}
While ($check -eq $false) {
    # Try to start Wasta WSL and genie systemd service.
    wsl --distribution 'Wasta-20.04' genie -i
    $check = $?
}

# Have to wait awhile, otherwise vcxsrv will fail to start.
$wait = 10
Write-Host "$wait more seconds..."
Start-Sleep -Seconds $wait

# Launch X Window for Wasta WSL.
& C:\'Program Files'\VcXsrv\vcxsrv.exe -ac -wgl -dpms -wr -query $env:computername-wsl
