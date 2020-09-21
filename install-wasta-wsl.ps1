# ------------------------------------------------------------------------------
# 1. User needs to first allow script execution in this PS window before this script will run.
# > Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process
#
# 2. This specific script may also have to be given permission to run.
# https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_signing
# Go to script in File Manager, right-click, select "Properties", select "Unblock".
# OR
# > Unblock-File -Path .\install-ubuntu-in-wsl.ps1
#
# 3. Script needs to be run with elevated privileges.
# ------------------------------------------------------------------------------

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
$BASE_PAR = "$env:APPDATA"
$BASE = "$BASE_PAR\Wasta-Linux"
$reboot = $false

# Create Wasta-Linux install folder.
Write-Host "Preparing installation folder at $BASE."
If ((Test-Path $BASE) -eq $false) {
    Write-Host "   Creating install folder at $BASE..."
    $null = New-Item -Path "$BASE_PAR" -Name "Wasta-Linux" -Type "directory"
}
If ("$PARENT" -ne "$BASE") {
    # Copy all files to Wasta-Linux folder, updating old ones if necessary.
    Write-Host "   Copying files into $BASE..."
    Copy-Item -Path "$PARENT\*" -Destination "$BASE" -Recurse -Force
}

# Enable VirtualMachinePlatform if not enabled.
Write-Host "Checking for VirtualMachinePlatform..."
$vmp_state = Get-WindowsOptionalFeature -Online -FeatureName 'VirtualMachinePlatform' | Select-Object -ExpandProperty 'State'
If ($vmp_state -eq 'Enabled') {
    $vmp_state = $true
} Else {
    # VirtualMachinePlatform supposedly enables WSL2.
    Write-Host "   Enabling VirtualMachinePlatform..."
    Enable-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform -NoRestart
    If ($? -eq $true) {
        $vmp_state = $true
        $reboot = $true
    } Else {
        $vmp_state = $false
        Write-Host "   Unable to enable VirtualMachinePlatform. Exiting."
        Exit 1
    }
}

# Enable Windows Subsystem for Linux if not enabled.
Write-Host "Checking for Windows Subsystem for Linux..."
$wsl_state = Get-WindowsOptionalFeature -Online -FeatureName 'Microsoft-Windows-Subsystem-Linux' | Select-Object -ExpandProperty 'State'
If ($wsl_state -eq 'Enabled') {
    $wsl_state = $true
} Else {
    Write-Host "   Enabling Microsoft-Windows-Subsystem-Linux."
    Enable-WindowsOptionalFeature -Online -FeatureName 'Microsoft-Windows-Subsystem-Linux' -NoRestart
    $wsl_state = $?
    $reboot = $true
    If ($wsl_state -eq $false) {
        Write-Host "   Unable to enable Microsoft-Windows-Subsystem-Linux. Exiting."
        Exit 1
    }
}

# Restart computer if needed.
If ($reboot -eq $true) {
    Write-Host "Reboot required before continuing. Please reboot and re-launch the script."
    Write-Host "You will need to again use the 'cd' command to change to the correct directory,"
    Write-Host "then you will need to run the previous 'Set-ExecutionPolicy Bypass -Scope Process'"
    Write-Host " command, then you will be able to run the script again with '.\install-wasta-wsl.ps1'"
    Write-Host ""
    $ans = Read-Host "Reboot now? [Y/n]"
    If (!$ans) {
        $ans = 'Y'
    }
    $ans = $ans.ToUpper()
    If ($ans -eq 'Y') {
        Restart-Computer
    } Else {
        Exit 1
    }
}

# Set WSL to version 2. No [easy?] way to verify the WSL version programmatically
#   before trying to set it because I can't figure out how to
#   "grep" the output of wsl commands!
# Ensure that WSL uses v2 by default.
Write-Host "Ensuring that WSL uses version 2 by default..."
wsl --set-default-version 2
$wsl2 = $?
If ($wsl2 -eq $false) {
    # Likely missing the kernel upgrade.
    Write-Host "   Downloading and installing the kernel update package... [14 MB]"
    # kernel update package [14MB]:
    $url = "https://wslstorestorage.blob.core.windows.net/wslblob/wsl_update_x64.msi"
    # Download kernel update installer.
    Invoke-WebRequest -Uri "$url" -OutFile "$BASE\wsl_update_x64.msi" -UseBasicParsing
    # Run installer.
    Start-Process "$BASE\wsl_update_x64.msi" -Wait
    wsl --set-version "$DISTRO" 2
    $wsl2 = $?
    If ($wsl2 -eq $false) {
        Write-Host "   Unable to install the kernel update package and set WSL to version 2. Exiting."
        Exit 1
    }
}

# Limit RAM allocated to all WSLs (including Wasta-WSL).
# https://docs.microsoft.com/en-us/windows/wsl/wsl-config
$cfg_path = "$HOME\.wslconfig"
If ((Test-Path $cfg_path) -eq $false) {
    Write-Host "Limiting Wasta-WSL to 4GB RAM and 2 CPUs..."
    New-Item "$cfg_path" -ItemType "File"
    Add-Content "$cfg_path" "[wsl2]"
    Add-Content "$cfg_path" "memory=4GB"
    Add-Content "$cfg_path" "processors=2"
}

# Install Wasta 20.04 if not installed.
Write-Host "Checking for existing installaltion of Wasta-20.04..."
$DISK1 = "rootfs" # WSL1
$DISK2 = "ext4.vhdx" # WSL2
$DISTRO = "Wasta-20.04"
$disk_path = Test-Path "$BASE\$DISK2"
If ($disk_path -eq $false) {
    # Download and install the distro. [2 GB]
    #   But first, deal with Drive's cookies hijinks.
    $drive = "https://drive.google.com"
    $id = "1ajcXQq_t1OIi1RU4XIigPqykLnjZO3QJ"
    $warn_url = "$drive/uc?export=download&id=$id"
    # Initialize session.
    $response = Invoke-WebRequest "$warn_url" -UseBasicParsing -SessionVariable session
    # Get unique confirm #.
    $confirm = $response.Content | Select-String 'confirm=([0-9a-zA-Z]+)&' | ForEach-Object {$_.Matches.Groups[1].Value}
    Write-Host "   The file Wasta-20.04.tar will be downloaded from the following link [about 2 GB]:"
    $url = "$drive/uc?export=download&confirm=$confirm&id=$id"
    Write-Host "$url"
    Write-Host "   Continue with download? [Y/n/x]"
    $ans = Read-Host "   Y = yes [default], n = no, x = use already-downloaded file"
    If (!$ans) {
        $ans = 'Y'
    }
    $ans = $ans.ToUpper()
    If ($ans -eq 'Y') {
        Write-Host "   Downloading $DISTRO.tar.gz... [2 GB]"
        Invoke-WebRequest -Uri "$url" -OutFile "$BASE\$DISTRO.tar.gz" -UseBasicParsing -WebSession $session
    } ElseIf ($ans -eq 'X') {
        Read-Host "   Manually copy Wasta-20.04.tar.gz into $BASE and press [Enter] to continue with installation."
    } Else {
        Write-Host "   Download aborted. Exiting."
        Exit 2
    }

    # Decompress the gz file.
    & "$BASE\scripts\un-gzip.ps1" "$BASE\$DISTRO.tar.gz"

    # Import into WSL.
    Write-Host "   Importing $DISTRO.tar into WSL. This could take several minutes..."
    wsl --import "$DISTRO" "$BASE" "$BASE\$DISTRO.tar"
    $disk_path = Test-Path "$BASE\$DISK2"
    If ($disk_path -eq $false) {
        Write-Host "   Unable to install $DISTRO. Exiting."
        Exit 1
    }
    # Default user is "root" when imported.
    # We will need to specify "wasta" user on wsl launch command line if launched manually:
    # > wsl --distribution 'Wasta-20.04' --user 'wasta'
}

# Install VcXsrv if not installed.
Write-Host "Checking for existing installation of VcXsrv..."
$vcxsrv = Test-Path "$C_PROG_FILES\VcXsrv\vcxsrv.exe"
If ($vcxsrv -eq $false) {
    Write-Host "   Downloading and installing VcXsrv X Window server... [41 MB]"
    $url = "https://sourceforge.net/projects/vcxsrv/files/latest/download"
    $url = "https://liquidtelecom.dl.sourceforge.net/project/vcxsrv/vcxsrv/1.20.8.1/vcxsrv-64.1.20.8.1.installer.exe"
    Invoke-WebRequest -Uri "$url" -OutFile "$BASE\vcxsrv.installer.exe" -UseBasicParsing
    # Run installer, accepting default location.
    #   Suggested: no Start Menu entry, no Desktop icon.
    Start-Process "$BASE\vcxsrv.installer.exe" -Wait
    $vcxsrv = Test-Path "$C_PROG_FILES\VcXsrv\vcxsrv.exe"
    If ($vcxsrv -eq $false) {
        Write-Host "   Unable to install VcXsrv. Exiting."
        Exit 1
    }
}

# Create Wasta-Linux launcher on Desktop and in Wasta-Linux folder once all parts are installed.
Write-Host "Verifying that all criteria are met..."
$launcher = $false
If ( ($vmp_state -eq $true) -and ($wsl_state -eq $true) -and ($disk_path -eq $true) -and ($wsl2 -eq $true) -and ($vcxsrv -eq $true) ) {
    $desktop_launcher = Join-Path ([Environment]::GetFolderPath("Desktop")) "Wasta-Linux.lnk"
    $wasta_launcher = "$BASE\Wasta-Linux.lnk"

    Write-Host "Creating Wasta-Linux launcher..."
    $target = "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe"
    $arg = "-ExecutionPolicy Bypass -File `"$BASE\scripts\launch-wasta-wsl.ps1`""
    $icon = "$BASE\files\wasta-linux.ico"
    $wasta_shortcut = (New-Object -comObject WScript.Shell).CreateShortcut($wasta_launcher)
    $wasta_shortcut.TargetPath = "$target"
    $wasta_shortcut.Arguments = "$arg"
    $wasta_shortcut.IconLocation = "$icon"
    $wasta_shortcut.WindowStyle = 7 # run minimized
    $wasta_shortcut.Save()

    Write-Host "Creating Desktop shortcut..."
    Copy-Item -Path "$wasta_launcher" -Destination "$desktop_launcher"
    $launcher = Test-Path "$desktop_launcher"
} Else {
    Write-Host ""
    Write-Host "Installation state"
    Write-Host "-----------------------------------------"
    Write-Host "VirtualMachinePlatform:            $vmp_state"
    Write-Host "Microsoft-Windows-Subsystem-Linux: $wsl_state"
    Write-Host "Wasta-20.04 installed:             $wsl_state"
    Write-Host "WSL set to v2 for Wasta:"          $wsl2
    Write-Host "VcXsrv installed:                  $vcxsrv"
    Write-Host "Launcher created:                  $launcher"
    Exit 1
}
