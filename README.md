# Wasta-WSL
Try Wasta-Linux in Windows using the Windows Subsystem for Linux

### Installation steps:
- Download this Wasta-WSL git repo as a zip file:
  - https://github.com/n8marti/wasta-wsl/archive/master.zip
- Extract zip folder to somewhere convenient (e.g. Downloads).
- Go to extracted location, right-click on "wasta-wsl-master" in the Address Bar.
- Choose "Copy Address" from the context menu.
- Start Windows PowerShell as Administrator by finding it in the Start Menu, right-clicking on it, and choosing "Run as Administrator".
- In the PowerShell window type "cd " (3 characters: "c", "d", " "), then paste the file address you copied earlier and hit [Enter], e.g.:
```
cd C:\Users\MyUser\Downloads\wasta-linux-master
```
- Temporarily allow script execution with this command (permission will be revoked when the PowerShell window is closed):
```
Set-ExecutionPolicy Bypass -Scope Process
```
- Type "y" then "<Enter>" to accept this change.
- Launch install-wasta-wsl.ps1 script with:
```
.\install-wasta-wsl.ps1
```
