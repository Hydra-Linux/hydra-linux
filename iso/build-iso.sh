#!/usr/bin/env bash
set -euo pipefail

# Hydra Linux ISO Builder
# Usage: sudo ./iso/build-iso.sh [desktop:plasma|gnome|xfce|sway]

DESKTOP="${1:-plasma}"
ISO_DATE="$(date +%Y%m%d)"
ISO_NAME="hydra-linux-${ISO_DATE}-x86_64.iso"
ISO_OUTPUT="$(realpath "$(dirname "$0")/..")/${ISO_NAME}"

CHROOT="/tmp/hydra-iso-build/chroot"
SQUASHFS="/tmp/hydra-iso-build/hydra-root.squashfs"
ISO_DIR="/tmp/hydra-iso-build/iso"
OVERLAY="$(realpath "$(dirname "$0")/overlay")"

# Validate desktop selection
case "$DESKTOP" in
  plasma|gnome|xfce|sway) ;;
  *) echo "Usage: $0 [plasma|gnome|xfce|sway]"; exit 1 ;;
esac

if [[ $EUID -ne 0 ]]; then
  echo "This script must be run as root." >&2
  exit 1
fi

echo "==> Building Hydra Linux ISO (desktop: ${DESKTOP})"

# Step 1: Create build directory
echo "==> Creating build directory structure..."
rm -rf /tmp/hydra-iso-build
mkdir -p "${CHROOT}" "${ISO_DIR}/boot/grub" "${ISO_DIR}/live"

# Step 2: Mount btrfs subvolumes (for snapshot support)
echo "==> Setting up btrfs subvolumes..."
# Create a loop device or tempfs for the chroot
mount -t tmpfs tmpfs "${CHROOT}"

# Step 3: Install base system with flash
echo "==> Installing base system into chroot..."
mkdir -p "${CHROOT}/var/lib/flash" "${CHROOT}/var/cache/flash"

# Copy overlay config
cp -r "${OVERLAY}"/* "${CHROOT}/"

# Initialize flash database and install base
flash --root="${CHROOT}" db init
flash --root="${CHROOT}" install base-layout linux-kernel grub

# Step 4: Install desktop environment
echo "==> Installing ${DESKTOP} desktop environment..."
flash --root="${CHROOT}" install "hydra-${DESKTOP}"

# Step 5: Create SquashFS
echo "==> Creating SquashFS (zstd compression)..."
mksquashfs "${CHROOT}" "${SQUASHFS}" -comp zstd -b 1M

# Step 6: Build initramfs
echo "==> Building initramfs..."
cp /tmp/hydra-iso-build/mkinitcpio.conf "${CHROOT}/etc/mkinitcpio.conf"
chroot "${CHROOT}" mkinitcpio -k /boot/vmlinuz-linux -g /boot/initramfs.img

# Step 7: Assemble ISO
echo "==> Assembling ISO..."
cp "${SQUASHFS}" "${ISO_DIR}/live/hydra-root.squashfs"
cp "${CHROOT}/boot/vmlinuz-linux" "${ISO_DIR}/boot/vmlinuz"
cp "${CHROOT}/boot/initramfs.img" "${ISO_DIR}/boot/initramfs.img"

# Copy GRUB config
cp "$(dirname "$0")/grub.cfg" "${ISO_DIR}/boot/grub/grub.cfg"

# Generate ISO with xorriso
xorriso -as mkisofs \
  -iso-level 3 \
  -full-iso9660-filenames \
  -volid "HYDRA_LINUX" \
  -eltorito-boot boot/grub/grub.cfg \
  -no-emul-boot \
  -boot-load-size 4 \
  -boot-info-table \
  -eltorito-catalog boot/grub/boot.cat \
  -grub2-boot-info \
  -grub2-mbr /usr/lib/grub/i386-pc/boot_hybrid.img \
  -output "${ISO_OUTPUT}" \
  "${ISO_DIR}"

echo "==> ISO built successfully: ${ISO_OUTPUT}"
ls -lh "${ISO_OUTPUT}"
