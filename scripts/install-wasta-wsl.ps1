
# User needs to first allow script execution in this PS window before this script will run.
#Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope Process
# TODO:
#   - Figure out delivery method of Wasta-Linux files.
#   - $BASE needs to be equivalent to script's parent directory.
#   - Limit Wasta-WSL RAM to 4GB.

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

#$BASE = "C:\Program Files\Wasta-WSL"
$BASE = $PSScriptRoot
New-Item -Path "C:\Program Files\" -Name "Wasta-Linux" -Type "directory"

# Enable VirtualMachinePlatform if not enabled.
$vmp_state = Get-WindowsOptionalFeature -Online -FeatureName 'VirtualMachinePlatform' | Select-Object -ExpandProperty 'State'
If ($vmp_state -ne 'Enabled') {
    # VirtualMachinePlatform supposedly enables WSL2.
    Enable-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform -NoRestart
}

# Enable Windows Subsystem for Linux if not enabled.
$wsl_state = Get-WindowsOptionalFeature -Online -FeatureName 'Microsoft-Windows-Subsystem-Linux' | Select-Object -ExpandProperty 'State'
If ($wsl_state -ne 'Enabled') {
    Enable-WindowsOptionalFeature -Online -FeatureName 'Microsoft-Windows-Subsystem-Linux' -NoRestart
    # kernel update package [14MB]:
    # https://wslstorestorage.blob.core.windows.net/wslblob/wsl_update_x64.msi
}

# Install Ubuntu 20.04 if not installed.
$distro = Get-AppxPackage -Name 'CanonicalGroupLimited.Ubuntu20.04onWindows'
If (!($distro)) {
    # Download and install the distro. [~450 MB]
    Invoke-WebRequest -Uri "https://aka.ms/wslubuntu2004" -OutFile "$BASE\wslubuntu2004.appx" -UseBasicParsing $RESUME
    Add-AppxPackage "$BASE\wslubuntu2004.appx"
}

# Install Wasta 20.04 if not installed.
$name = "Wasta-20.04"
$distro = "$BASE\$name"
If (!(Test-Path $distro)) {
    # Download and install the distro. [? MB]
    #Invoke-WebRequest -Uri "https://github.com/wasta-linux/wasta-wsl/"
}

# TODO: Limit RAM allocated to Wasta-WSL.

# Install VcXsrv if not installed.
$vcxsrv = Get-ChildItem C:\'Program Files'\VcXsrv\vcxsrv.exe* -ErrorAction 'silentlycontinue'
If (!($vcxsrv)) {
    Invoke-WebRequest -Uri "https://sourceforge.net/projects/vcxsrv/files/latest/download" -OutFile "$BASE\vcxsrv.installer.exe" -UseBasicParsing
    # Run installer, but specify Wasta-Linux folder as parent instead of Program Files.
    #   TODO: I can't find any evidence of being able to script the installation.
    # Run installer, accepting default location.
    #   Suggested: no Start Menu entry, no Desktop icon.
    "$BASE\vcxsrv.installer.exe"
}

# Create Wasta-Linux launcher on Desktop and in Wasta-Linux folder once all parts are installed.
If ( ($vmp_state) -and ($wsl_state) -and ($distro) -and ($vcxsrv) ) {
    $desktop_launcher = Join-Path ([Environment]::GetFolderPath("Desktop")) "Wasta-Linux.lnk"
    $wasta_launcher = "$BASE\Wasta-Linux.lnk"
    If (!(Get-Item $wasta_launcher -ErrorAction 'silentlycontinue')) {
        $target = "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe"
        $arg = "-command & {& C:\'Program Files'\VcXsrv\vcxsrv.exe -ac -wgl -dpms -wr -query $env:computername-wsl}"
        $icon = "$BASE\wasta-linux.ico"
        $desktop_shortcut = (New-Object -comObject WScript.Shell).CreateShortcut($desktop_launcher)
        $wasta_shortcut = (New-Object -comObject WScript.Shell).CreateShortcut($wasta_launcher)
        $desktop_shortcut.TargetPath = $wasta_shortcut.TargetPath = "$target"
        $desktop_shortcut.Arguments = $wasta_shortcut.Arguments = "$arg"
        $desktop_shortcut.IconLocation = $wasta_shortcut.IconLocation = "$icon"
        $desktop_shortcut.Save()
        $wasta_shortcut.Save()
    }
}

# Restart computer if needed.
If (New-Object -ComObject Microsoft.Update.SystemInfo).RebootRequired {
    Restart-Computer
}
