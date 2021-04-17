- [x] Add Wasta-Linux icon file to repo.
- [x] Export Wasta from wsl.
- [x] Test import of Wasta into WSL.
- [x] Fix colord polkit issue.
- [x] Test decompression from .tar.gz.
- [x] Verify installation process on clean system.
- [ ] Build in checksums to both the tar.gz and the tar files.
- [ ] Clarify during boot-up that it's checking for a network connection to Wasta
- [ ] Figure out why the X server window might get slugging when logging in to Cinnamon
- [ ] Upload Wasta-20.04.tar(.gz) to... Drive? GitHub? cloud server?
- [ ] Create Distro Launcher?: https://github.com/Microsoft/WSL-DistroLauncher


### Overview for building the base image
- VM Prep 1: Use Virt-Manager for VM testing (e.g. Wasta host / Win10 guest / WSL2)
- VM Prep 2: Enable nested virtualization on host:
    - $ cat /etc/modprobe.d/kvm_intel[|amd].conf
    - options kvm-intel[|amd] nested=Y
- VM Prep 3: Virt-Manager VM config > Processors > Configuration > Copy host's proc config

- Step 1: Install Ubuntu 20.04 in WSL
- Step 2: Convert Ubuntu 20.04 to Wasta 20.04 using convert-ubuntu-to-wasta.sh.
- Step 3: Enable Windows access to Wasta desktop (via VcXsrv server)
- Step 4: Simplify access to Wasta desktop (create launcher for VcXsrv command)
