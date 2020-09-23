# Parts to uninstall:
#   - Wasta-Linux Launchers
#   - Wasta-Linux WSL distro
#   - VcXsrv
#   - .wslconfig
#   - Wasta-Linux folder

$USER_DIR = "$HOME"
$DESKTOP = "$USER_DIR\Desktop"
$VCXSRV_DIR = "$env:ProgramFiles\VcXsrv"
$WASTA_DIR = "$env:$APPDATA\Wasta-Linux"

Write-Host "This script can either remove all files installed by install-wasta-wsl.ps1,"
Write-Host "or ask for confirmation for each part."
$ans = Read-Host "Remove all Wasta-Linux files? [Y/n]"
If (!$ans) {
    $ans = 'Y'
}
$ans = $ans.ToUpper()

# Remove desktop launcher.
If ($ans -ne 'Y') {
    $a = Read-Host "Remove desktop launcher? [Y/n]"
    If (!$a) {
        $a = 'Y'
    }
    $a = $ans.ToUpper()
} Else {
    $a = $ans
}
If ($a -eq 'Y') {
    $desktop_launcher_path = Test-Path "$DESKTOP\Wasta-Linux.lnk"
    If ($desktop_launcher_path -eq $true) {
        Remove-Item -Path "$DESKTOP\Wasta-Linux.lnk"
    }
}

# Uninstall VcXsrv.
If ($ans -ne 'Y') {
    $a = Read-Host "Uninstall VcXsrv? [Y/n]"
    If (!$a) {
        $a = 'Y'
    }
    $a = $ans.ToUpper()
} Else {
    $a = $ans
}
If ($a -eq 'Y') {
    $vcxsrv_path = Test-Path "$VCXSRV_DIR\vcxsrv.exe"
    If ($vcxsrv_path -eq $true) {
        Start-Process "$VCXSRV_DIR\uninstall.exe" -Wait
    }
}

# Remove .wslconfig.
If ($ans -ne 'Y') {
    $a = Read-Host "Remove .wslconfig file? [Y/n]"
    If (!$a) {
        $a = 'Y'
    }
    $a = $ans.ToUpper()
} Else {
    $a = $ans
}
If ($a -eq 'Y') {
    $cfg_path = "$USER_DIR\.wslconfig"
    If ($cfg_path -eq $true) {
        Remove-Item -Path "$USER\.wslconfig"
    }
}

# Remove Wasta distro from WSL.
If ($ans -ne 'Y') {
    $a = Read-Host "Remove Wasta-20.04 from WSL? [Y/n]"
    If (!$a) {
        $a = 'Y'
    }
    $a = $ans.ToUpper()
} Else {
    $a = $ans
}
If ($a -eq 'Y') {
    wsl --terminate "Wasta-20.04"
    wsl --unregister "Wasta-20.04"
}

# Remove Wasta-Linux folder.
If ($ans -ne 'Y') {
    $a = Read-Host "Remove Wasta-Linux folder and remaining files? [Y/n]"
    If (!$a) {
        $a = 'Y'
    }
    $a = $ans.ToUpper()
} Else {
    $a = $ans
}
If ($a -eq 'Y') {
    $wasta_dir_path = Test-Path "$WASTA_DIR"
    If ($wasta_dir_path -eq $true) {
        Remove-Item -Path $WASTA_DIR -Recurse
    }
}
