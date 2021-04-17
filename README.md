# Wasta-WSL
Try Wasta-Linux in Windows using the Windows Subsystem for Linux

### Requirements:
- Windows 10 v2004 (actually depends on WSL2, which may be available on some earlier versions)
- At least 8 GB of memory (up to 4 GB will be used by Wasta-Linux)
- At least 16 GB of storage space in the drive holding your user folder (Drive C: for most people)
- The ability to download around 2 GB of files for installation.

### Tips:
- Download the Wasta disk image file ahead of time to speed things up. You can get it from Drive:
  https://drive.google.com/uc?export=download&id=1p5WefBbHC-H9n-3MbSyulZoUbjTbz5oV
- If you already happen to use WSL, this shouldn't cause any problems for you, except that this creates a .wslconfig file in your User folder to limit WSL to 4GB RAM and 2 CPUs. If you don't like this, you can modify or delete the file according to your preferences. It will be found at C:\Users\<User Name>\.wslconfig.
- On Windows 10 Pro (and maybe Home edition)...

### Installation steps:
- Download the Wasta-WSL script package as a zip file from the Releases page:
  - https://github.com/n8marti/wasta-wsl/releases
- Extract zip folder to somewhere convenient (e.g. Downloads).
- Go to extracted location, right-click on "wasta-wsl-v[version.number]" in the Address Bar.
- Choose "Copy Address" from the context menu.
- Start Windows PowerShell by finding it in the Start Menu.
- In the PowerShell window type "cd " (3 characters: "c", "d", " "), then paste the file address you copied earlier and hit [Enter], e.g.:
```
cd C:\Users\MyUser\Downloads\wasta-linux-v0.1
```
- Temporarily allow script execution with this command (permission will be revoked when the PowerShell window is closed):
```
Set-ExecutionPolicy Bypass -Scope Process
```
```
Execution Policy Change
The execution policy helps protect you from scripts that you do not trust. Changing the execution policy might expose
you to the security resks described in the about_Execution_Policies help topic at
https://go.microsoft.com/fwlink/?LinkID=135170. Do you want to change the execution policy?
[Y] Yes  [A] Yes to All  [N] No  [L] No to All  [S] Suspend  [?] Help (default is "N"): _
```
- Type "y", then "[Enter]" to accept this change.
- Launch install-wasta-wsl.ps1 script with:
```
.\install-wasta-wsl.ps1
```
