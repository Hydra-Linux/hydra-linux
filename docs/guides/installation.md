# Installation Guide

## Prerequisites
- x86_64 CPU (Intel or AMD)
- 2 GB RAM minimum (8 GB recommended)
- 20 GB storage minimum (64 GB recommended)

## Method 1: Live ISO
1. Download the Hydra Linux ISO
2. Write to USB: `dd if=hydra-linux.iso of=/dev/sdX bs=4M status=progress`
3. Boot from USB
4. Follow the Calamares installer prompts
5. Choose your desktop environment during installation
6. Reboot into Hydra Linux

## Method 2: Bootstrap from existing Linux
1. `git clone https://github.com/Hydra-Linux/hydra-linux`
2. `cd hydra-linux`
3. `sudo ./bootstrap/build-all.sh`
4. Wait for the 4-stage bootstrap to complete
5. Reboot

## Post-Installation
- Set your hostname: `echo "myhost" > /etc/hostname`
- Create a user: `useradd -m -G wheel username`
- Set password: `passwd username`
- Configure network: `flash install networkmanager`
