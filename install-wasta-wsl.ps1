
# User needs to first allow script execution in this PS window before this script will run.
#Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process
#
# This specific script may also have to be given permission to run.
# https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_signing?view=powershell-7
# Go to script in File Manager, right-click, select "Properties", select "Unblock".
# OR
# > Unblock-File -Path .\install-ubuntu-in-wsl.ps1

# Script needs to be run with elevated privileges.

# Can downloads be resumable (PS >or= 6.1.0)?
$RESUME = ''
$PSVersionMaj = $host.Version.Major
$PSVersionMin= $host.Version.Minor
If ($PSVersionMaj -eq 6) {
    If ($PSVersionMin -ge 1) {
        $RESUME = '-Resume'
    }
} ElseIf ($PSVersionMaj -gt 6) { $RESUME = '-Resume' }

$PARENT = "$PSScriptRoot"
$C_PROG_FILES = $env:ProgramFiles
$BASE = "$C_PROG_FILES\Wasta-Linux"

# Create Wasta-Linux install folder.
Write-Host "Creating install folder at $BASE and copying files."
If ((Test-Path $BASE) -eq $false) {
    New-Item -Path "$C_PROG_FILES" -Name "Wasta-Linux" -Type "directory"
}
# Copy all files to Wasta-Linux folder, updating if necessary.
Copy-Item -Path "$PARENT\*" -Destination "$BASE" -Recurse -Force

# Limit RAM allocated to all WSLs (including Wasta-WSL).
# https://docs.microsoft.com/en-us/windows/wsl/wsl-config
$cfg_path = "$HOME\.wslconfig"
if ((Test-Path $cfg_path) -eq $false) {
    Write-Host "Limiting Wasta-WSL to 4GB RAM and 2 CPUs."
    New-Item "$cfg_path" -ItemType "File"
    Add-Content "$cfg_path" "[wsl2]"
    Add-Content "$cfg_path" "memory=4GB"
    Add-Content "$cfg_path" "processors=2"
}

# Enable VirtualMachinePlatform if not enabled.
$vmp_state = Get-WindowsOptionalFeature -Online -FeatureName 'VirtualMachinePlatform' | Select-Object -ExpandProperty 'State'
If ($vmp_state -eq 'Enabled') {
    $vmp_state -eq $true
} Else {
    # VirtualMachinePlatform supposedly enables WSL2.
    Write-Host "Enabling VirtualMachinePlatform."
    Enable-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform -NoRestart
    If ($? -eq 0) {
        $vmp_state = $true
    } Else {
        $vmp_state = $false
        Write-Host "Unable to enable VirtualMachinePlatform. Exiting."
        Exit 1
    }
}

# Enable Windows Subsystem for Linux if not enabled.
$wsl_state = Get-WindowsOptionalFeature -Online -FeatureName 'Microsoft-Windows-Subsystem-Linux' | Select-Object -ExpandProperty 'State'
If ($wsl_state -eq 'Enabled') {
    $wsl_state = $true
    } Else {
    Write-Host "Enabling Microsoft-Windows-Subsystem-Linux."
    Enable-WindowsOptionalFeature -Online -FeatureName 'Microsoft-Windows-Subsystem-Linux' -NoRestart
    If ($? -eq 0) {
        $wsl_state = $true
    } Else {
        $wsl_state = $false
        Write-Host "Unable to enable Microsoft-Windows-Subsystem-Linux. Exiting."
        Exit 1
    }
    # kernel update package [14MB]:
    # https://wslstorestorage.blob.core.windows.net/wslblob/wsl_update_x64.msi
}

# Install Ubuntu 20.04 if not installed.
#$DISTRO = Get-AppxPackage -Name 'CanonicalGroupLimited.Ubuntu20.04onWindows'
#If (!($DISTRO)) {
#    # Download and install the distro. [~450 MB]
#    Invoke-WebRequest -Uri "https://aka.ms/wslubuntu2004" -OutFile "$BASE\wslubuntu2004.appx" -UseBasicParsing $RESUME
#    Add-AppxPackage "$BASE\wslubuntu2004.appx"
#}

# Install Wasta 20.04 if not installed.
$DISK = "ext4"
$DISTRO = "Wasta-20.04"
$disk_path = Test-Path "$BASE\$DISK"
If ($disk_path -eq $false)) {
    # Download and install the distro. [? MB]
    Write-Host "You need to download the Wasta-20.04 tar file from here:"
    Write-Host "https://link.to.Wasta-20.04.tar"
    #Invoke-WebRequest -Uri "https://github.com/wasta-linux/wasta-wsl/"
    Write-Host "wsl --import "$DISTRO" "$BASE" "$BASE\$DISTRO.tar""
    If ($? -eq 0) {
        $disk_path = $true
    } Else {
        $disk_path = $false
        Write-Host "Unable to install $DISTRO. Exiting."
        Exit 1
    }
    # Default user is "root" when imported.
    # We will need to specify "wasta" on wsl launch command line if launched manually:
    #   > wsl --distribution 'Wasta-20.04' --user 'wasta'
}

# Install VcXsrv if not installed.
$vcxsrv = Test-Path "$C_PROG_FILES\VcXsrv\vcxsrv.exe"
If ($vcxsrv -eq $false) {
    Write-Host "Downloading and installing VcXsrv X Window server. [41 MB]"
    Invoke-WebRequest -Uri "https://sourceforge.net/projects/vcxsrv/files/latest/download" -OutFile "$BASE\vcxsrv.installer.exe" -UseBasicParsing
    # Run installer, accepting default location.
    #   Suggested: no Start Menu entry, no Desktop icon.
    & "$BASE\vcxsrv.installer.exe"
    If ($? -eq 0) {
        $vcxsrv = $true
    } Else {
        $vcxsrv = $false
        Write-Host "Unable to install VcXsrv. Exiting."
        Exit 1
    }
}

# Create Wasta-Linux launcher on Desktop and in Wasta-Linux folder once all parts are installed.
If ( ($vmp_state -eq $true) -and ($wsl_state -eq $true) -and ($disk_path -eq $true) -and ($vcxsrv -eq $true) ) {
    $desktop_launcher = Join-Path ([Environment]::GetFolderPath("Desktop")) "Wasta-Linux.lnk"
    $wasta_launcher = "$BASE\Wasta-Linux.lnk"

    Write-Host "Creating Wasta-Linux launcher."
    $target = "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe"
    $arg = "-ExecutionPolicy Bypass -File $BASE\scripts\launch-wasta-wsl.ps1'"
    $icon = "$BASE\files\wasta-linux.ico"
    $wasta_shortcut = (New-Object -comObject WScript.Shell).CreateShortcut($wasta_launcher)
    $wasta_shortcut.TargetPath = "$target"
    $wasta_shortcut.Arguments = "$arg"
    $wasta_shortcut.IconLocation = "$icon"
    $wasta_shortcut.WindowStyle = 7 # run minimized
    $wasta_shortcut.Save()
    If ((Test-Path "$desktop_launcher") -eq $false) {
        Write-Host "Creating Desktop shortcut."
        Copy-Item -Path "$wasta_launcher" -Destination "$desktop_launcher"
    }
}

# Restart computer if needed.
If ((New-Object -ComObject Microsoft.Update.SystemInfo).RebootRequired) {
    $ans = "Reboot required. Reboot now? [Y/n]: "
    If (!$ans) {
        $ans = 'Y'
    }
    $ans.ToUpper()
    If ($ans -eq 'Y') {
        Restart-Computer
    }
}
