- [x] Add Wasta-Linux icon file to repo.
- [x] Export Wasta from wsl.
- [x] Test import of Wasta into WSL.
- [ ] Test compression to .tar.gz.
- [ ] Test decompression from .tar.gz.
- [ ] Fix colord polkit issue.
- [ ] Verify installation process on clean system.
- [ ] Upload Wasta-20.04.tar(.gz) to github?
- [ ] Create Distro Launcher?: https://github.com/Microsoft/WSL-DistroLauncher


### Overview
- VM Prep 1: Use Virt-Manager for VM testing (e.g. Wasta host / Win10 guest / WSL2)
- VM Prep 2: Enable nested virtualization:
    - $ cat /etc/modprobe.d/kvm_intel[|amd].conf
    - options kvm-intel[|amd] nested=Y
- VM Prep 3: Virt-Manager VM config > Processors > Configuration > Copy host's proc config
- Step 1: Install Ubuntu 20.04 in WSL
- Step 2: Convert Ubuntu 20.04 to Wasta 20.04 using convert-ubuntu-to-wasta.sh.
- Step 3: Enable Windows access to Wasta desktop (either via X server or RDP)
- Step 4: Simplify access to Wasta desktop (create launcher if possible)
