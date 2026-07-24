# Installation Guide

## Prerequisites

- x86_64 (64-bit) CPU
- 2 GB RAM (4 GB recommended)
- 20 GB available storage (SSD preferred)
- USB drive (4 GB+) or blank DVD
- Internet connection

## Step 1: Download the ISO

Download the latest Hydra Linux ISO from the [releases page](https://github.com/yourorg/hydra-linux/releases).

Verify the checksum:

```bash
sha256sum hydra-linux-*.iso
```

## Step 2: Create Bootable Media

### USB Drive (Linux)

```bash
sudo dd if=hydra-linux-YYYYMMDD-x86_64.iso of=/dev/sdX bs=4M status=progress
sync
```

Replace `/dev/sdX` with your USB device (check with `lsblk`).

### USB Drive (Windows)

Use [Rufus](https://rufus.ie/) or [balenaEtcher](https://www.balena.io/etcher/).

### DVD

```bash
growisofs -dvd-compat -Z /dev/dvd=hydra-linux-YYYYMMDD-x86_64.iso
```

## Step 3: Boot from Media

1. Insert the installation media and reboot
2. Enter the boot menu (typically F12, F2, Del, or Esc)
3. Select the USB/DVD drive
4. Choose **Hydra Linux Live** from the GRUB menu

## Step 4: Run the Installer

From the live desktop, launch the installer:

```bash
sudo hydra-install
```

The installer will guide you through:

1. **Language and locale** selection
2. **Partitioning** — manual (ext4, btrfs, or ZFS) or guided
3. **Filesystem** creation
4. **Base system** installation
5. **Bootloader** (GRUB) configuration
6. **User account** creation
7. **Desktop environment** selection (optional)

## Step 5: First Boot

After installation completes and you reboot:

1. **Log in** with the user account created during installation
2. **Run updates**:
   ```bash
   sudo flash update && sudo flash upgrade
   ```
3. **Configure additional software**:
   ```bash
   sudo flash install firefox thunderbird libreoffice
   ```
4. **Enable services** (if needed):
   ```bash
   sudo systemctl enable --now NetworkManager
   ```

## Troubleshooting

| Issue | Solution |
|-------|----------|
| Black screen at boot | Use "Safe Mode" from GRUB |
| No WiFi | `sudo systemctl start NetworkManager` |
| Installer won't start | Run `hydra-install` from terminal |
| Out of space | Check `flash clean` to clear build cache |

For further help, visit our [GitHub Issues](https://github.com/yourorg/hydra-linux/issues).
