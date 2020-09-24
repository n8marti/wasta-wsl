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

#This will self elevate the script so with a UAC prompt since this script needs
#   to be run as an Administrator in order to function properly.
If (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]'Administrator')) {
    Write-Host "Restarting the script as Administrator. Please choose `"allow`" in the UAC prompt."
    Start-Sleep 1
    Start-Process powershell.exe -ArgumentList ("-NoProfile -ExecutionPolicy Bypass -File `"{0}`"" -f $PSCommandPath) -Verb RunAs
    Exit
}

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

$vmp_state = ''
$wsl_state = ''
$reboot = ''
$disk_path = ''
$wsl2 = ''
$vcxsrv = ''
$launcher = ''


function Error-Exit {
    Write-Host ""
    Write-Host "Installation state"
    Write-Host "-----------------------------------------"
    Write-Host "VirtualMachinePlatform:            $vmp_state"
    Write-Host "Microsoft-Windows-Subsystem-Linux: $wsl_state"
    Write-Host "Wasta-20.04 installed:             $disk_path"
    Write-Host "Reboot needed?                     $reboot"
    Write-Host "WSL set to v2 for Wasta:"          $wsl2
    Write-Host "VcXsrv installed:                  $vcxsrv"
    Write-Host "Launcher created:                  $launcher"
    Write-Host ""
    Write-Host ""
    Exit 1
}



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
$reboot = $false
If ($vmp_state -eq 'Enabled') {
    $vmp_state = $true
} Else {
    # VirtualMachinePlatform needed for WSL2.
    Write-Host "   Enabling VirtualMachinePlatform..."
    Enable-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform -NoRestart
    If ($? -eq $true) {
        $vmp_state = $true
        $reboot = $true
    } Else {
        $vmp_state = $false
        Write-Host "   Unable to enable VirtualMachinePlatform. Exiting."
        Error-Exit
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
        Error-Exit
    }
}

# Restart computer if needed.
If ($reboot -eq $true) {
    Write-Host "Reboot required before continuing. Please reboot and re-launch the script."
    Write-Host "You will need to again use the 'cd' command to change to the correct directory,"
    Write-Host "then you will need to run the previous 'Set-ExecutionPolicy Bypass -Scope Process'"
    Write-Host "command, then you will be able to run the script again with '.\install-wasta-wsl.ps1'"
    Write-Host ""
    $ans = Read-Host "Reboot now? [Y/n]"
    If (!$ans) {
        $ans = 'Y'
    }
    $ans = $ans.ToUpper()
    If ($ans -eq 'Y') {
        Restart-Computer
    } Else {
        Error-Exit
    }
}

# Set WSL to version 2. No [easy?] way to verify the WSL version programmatically
#   before trying to set it because I can't figure out how to "grep" the output
#   of wsl commands!
# Possible registry keys to check:
# HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Products\93D27E81C293D914B9684C6C334BEC9D\InstallProperties
# DisplayName REG_SZ "Windows Subsystem for Linux Update"
#Write-Host "Ensuring that WSL uses version 2 by default..."
#wsl --set-default-version 2

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
Write-Host "Checking for existing installation of Wasta-20.04..."
$DISK1 = "rootfs" # WSL1
$DISK2 = "ext4.vhdx" # WSL2
$DISTRO = "Wasta-20.04"
$disk_path = Test-Path "$BASE\$DISK2"
If ($disk_path -eq $false) {
    # Likely missing the kernel upgrade.
    Write-Host "   Downloading and installing the kernel update package... [14 MB]"
    # kernel update package [14MB]:
    $msi = "wsl_update_x64.msi"
    $msi_path = Test-Path "$BASE\$msi"
    If ($msi_path -eq $false) {
        $url = "https://wslstorestorage.blob.core.windows.net/wslblob/$msi"
        # Download kernel update installer.
        Invoke-WebRequest -Uri "$url" -OutFile "$BASE\$msi" -UseBasicParsing
    }
    # Run installer.
    Start-Process "$BASE\$msi" -Wait
    wsl --set-default-version 2
    $wsl2 = $?

    # Download and install the distro. [2 GB]
    $gz = "$DISTRO.tar.gz"
    $gz_path = Test-Path "$BASE\$gz"
    If ($gz_path -eq $false) {
        # Download tar.gz, but first deal with Drive's cookies hijinks.
        $drive = "https://drive.google.com"
        $id = "1ajcXQq_t1OIi1RU4XIigPqykLnjZO3QJ" # 20.04 BETA
        $id = "1p5WefBbHC-H9n-3MbSyulZoUbjTbz5oV" # 20.04.1
        $warn_url = "$drive/uc?export=download&id=$id"
        # Initialize session.
        $response = Invoke-WebRequest "$warn_url" -UseBasicParsing -SessionVariable session
        # Get unique confirm #.
        $confirm = $response.Content | Select-String 'confirm=([0-9a-zA-Z]+)&' | ForEach-Object {$_.Matches.Groups[1].Value}
        Write-Host "   The file Wasta-20.04.tar will be downloaded from the following link [about 2 GB]:"
        $url = "$drive/uc?export=download&confirm=$confirm&id=$id"
        Write-Host "$url"
        Write-Host "   Continue with download? [Y/n/x]"
        $ans = Read-Host "   Y = yes [default], n = no, x = use already-downloaded file $gz"
        If (!$ans) {
            $ans = 'Y'
        }
        $ans = $ans.ToUpper()
        If ($ans -eq 'Y') {
            Write-Host "   Downloading $gz... [2 GB]"
            Invoke-WebRequest -Uri "$url" -OutFile "$BASE\$gz" -UseBasicParsing -WebSession $session
        } ElseIf ($ans -eq 'X') {
            Write-Host "   Manually copy $gz into $BASE"
            Read-Host "   Then press [Enter] to continue with installation."
        } Else {
            Write-Host "   Download aborted. Exiting."
            Error-Exit
        }
    }

    $tar = "$DISTRO.tar"
    $tar_path = Test-Path "$BASE\$tar"
    If ($tar_path -eq $false) {
        # Decompress the gz file.
        & "$BASE\scripts\un-gzip.ps1" "$BASE\$gz"
    }

    # Import into WSL.
    Write-Host "   Importing $tar into WSL. This could take several minutes..."
    wsl --import "$DISTRO" "$BASE" "$BASE\$tar"
    $disk_path = Test-Path "$BASE\$DISK2"
    If ($disk_path -eq $false) {
        Write-Host "   Unable to import the $tar file. Please restart the installer to try again."
        Error-Exit
    }
    # Default user is "root" when imported.
    # We will need to specify "wasta" user on wsl launch command line if launched manually:
    # > wsl --distribution 'Wasta-20.04' --user 'wasta'
} Else {
    $wsl2 = $true
}

# Install VcXsrv if not installed.
Write-Host "Checking for existing installation of VcXsrv..."
$vcxsrv = Test-Path "$C_PROG_FILES\VcXsrv\vcxsrv.exe"
If ($vcxsrv -eq $false) {
    Write-Host "   Downloading and installing VcXsrv X Window server... [41 MB]"
    $inst = "vcxsrv.installer.exe"
    $inst_path = Test-Path "$BASE\$inst"
    If ($inst_path -eq $false) {
        $url = "https://sourceforge.net/projects/vcxsrv/files/latest/download"
        $url = "https://liquidtelecom.dl.sourceforge.net/project/vcxsrv/vcxsrv/1.20.8.1/vcxsrv-64.1.20.8.1.installer.exe"
        Invoke-WebRequest -Uri "$url" -OutFile "$BASE\$inst" -UseBasicParsing
    }
    # Run installer, accepting default location.
    #   Suggested: no Start Menu entry, no Desktop icon.
    Start-Process "$BASE\$inst" -Wait
    $vcxsrv = Test-Path "$C_PROG_FILES\VcXsrv\vcxsrv.exe"
    If ($vcxsrv -eq $false) {
        Write-Host "   Unable to install VcXsrv. Exiting."
        Error-Exit
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
    Write-Host "Failed to install $DISTRO."
    Error-Exit
}
Write-Host ""
Write-Host ""
