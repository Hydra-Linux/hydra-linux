#!/bin/bash -e
# Hydra Linux ISO Builder - Practical Bootstrap ISO
# Builds a bootable ISO containing flash + all recipes + bootstrap scripts

ISO_DATE="$(date +%Y%m%d)"
ISO_NAME="hydra-linux-dev-${ISO_DATE}-x86_64.iso"
PROJECT_DIR="/home/oliwier/hydra-linux"
OUTPUT_DIR="$PROJECT_DIR"
WORK="/tmp/hydra-iso-build"

rm -rf "$WORK"
mkdir -p "$WORK"/{rootfs,iso/{live,boot/grub},packages}

echo "==> Building minimal root filesystem..."

# Create base directory structure
mkdir -p "$WORK/rootfs"/{bin,dev,etc,home,proc,sys,mnt,root,tmp,var/{lib,log,cache}}
mkdir -p "$WORK/rootfs/usr"/{bin,lib,share,lib/flash/recipes}
mkdir -p "$WORK/rootfs/etc/flash"
mkdir -p "$WORK/rootfs/boot"

# Copy flash binary and config
cp "$PROJECT_DIR/flash/flash" "$WORK/rootfs/usr/bin/flash"
chmod 755 "$WORK/rootfs/usr/bin/flash"

cat > "$WORK/rootfs/etc/flash/flash.conf" << 'CONF'
[paths]
root = "/"
db = "/var/lib/flash/flash.db"
cache = "/var/cache/flash"
build_dir = "/var/cache/flash/build"
recipes_dir = "/usr/lib/flash/recipes"

[build]
sandbox = false
jobs = 4
source_threshold = 104857600
binary_threshold = 471859200

[gpg]
keyring = "/etc/flash/trusted-keys"

[install]
backup = false

[repos]
default = "https://github.com/Hydra-Linux/hydra-linux"
CONF

# Copy all recipes
cp -r "$PROJECT_DIR/recipes/"* "$WORK/rootfs/usr/lib/flash/recipes/"

# Copy bootstrap scripts
cp -r "$PROJECT_DIR/bootstrap" "$WORK/rootfs/root/"
chmod +x "$WORK/rootfs/root/bootstrap/"*.sh

# Copy documentation
mkdir -p "$WORK/rootfs/usr/share/doc/hydra"
cp -r "$PROJECT_DIR/docs/guides/"* "$WORK/rootfs/usr/share/doc/hydra/"

# Copy busybox for basic shell utilities
BUSYBOX=$(which busybox 2>/dev/null || echo "")
if [ -n "$BUSYBOX" ]; then
  cp "$BUSYBOX" "$WORK/rootfs/bin/busybox"
  for applet in sh ls cp mv rm cat echo mount umount grep sed clear vi; do
    ln -sf /bin/busybox "$WORK/rootfs/bin/$applet"
  done
fi

# Copy bash
cp /bin/bash "$WORK/rootfs/bin/" 2>/dev/null || true

# Create /init script for live boot
cat > "$WORK/rootfs/init" << 'INIT'
#!/bin/busybox sh
mount -t proc proc /proc
mount -t sysfs sysfs /sys
mount -t devtmpfs devtmpfs /dev
echo "=== Hydra Linux - Developer Live Environment ==="
echo "flash package manager is ready at /usr/bin/flash"
echo "Recipes are at /usr/lib/flash/recipes/"
echo "Bootstrap scripts at /root/bootstrap/"
echo ""
cat /etc/motd 2>/dev/null
exec /bin/sh
INIT
chmod +x "$WORK/rootfs/init"

# MOTD
cat > "$WORK/rootfs/etc/motd" << 'MOTD'
╔══════════════════════════════════════╗
║         Hydra Linux v1.0            ║
║     Many heads. One system.         ║
╚══════════════════════════════════════╝

Commands:
  flash install <pkg>    Build & install package
  flash make <pkg>       Build without installing
  flash list             List installed packages

To bootstrap the full system:
  cd /root && ./bootstrap/build-all.sh

Documentation: /usr/share/doc/hydra/
MOTD

echo "==> Creating SquashFS..."
mksquashfs "$WORK/rootfs" "$WORK/iso/live/hydra-root.squashfs" -comp zstd -b 1M -noappend

echo "==> Setting up kernel and initramfs..."
# Use current kernel
cp /boot/vmlinuz-linux "$WORK/iso/boot/vmlinuz" 2>/dev/null || \
cp /boot/vmlinuz-* "$WORK/iso/boot/vmlinuz" 2>/dev/null || \
echo "WARNING: No kernel found, ISO won't be bootable"

# Build initramfs with mkinitcpio
mkdir -p "$WORK/initramfs"
cat > "$WORK/mkinitcpio.conf" << 'MKINIT'
MODULES=()
BINARIES=(/usr/bin/flash)
FILES=()
HOOKS=(base udev autodetect modconf block filesystems keyboard)
COMPRESSION=zstd
MKINIT

cp "$WORK/rootfs/init" "$WORK/initramfs/init"
cp "$WORK/rootfs/bin/busybox" "$WORK/initramfs/bin/" 2>/dev/null || true
cd "$WORK/initramfs"
find . | cpio -o -H newc | zstd > "$WORK/iso/boot/initramfs.img" 2>/dev/null

echo "==> Setting up GRUB..."
cat > "$WORK/iso/boot/grub/grub.cfg" << 'GRUB'
set timeout=10
set default=0

menuentry "Hydra Linux - Developer Live" {
  linux /boot/vmlinuz root=/dev/sda1 quiet
  initrd /boot/initramfs.img
}

menuentry "Hydra Linux - Safe Mode" {
  linux /boot/vmlinuz root=/dev/sda1 nomodeset
  initrd /boot/initramfs.img
}

menuentry "Boot from first disk" {
  set root=(hd0)
  chainloader +1
}

menuentry "Shutdown" {
  halt
}

menuentry "Reboot" {
  reboot
}
GRUB

echo "==> Building ISO with xorriso..."
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
  -output "${OUTPUT_DIR}/${ISO_NAME}" \
  "$WORK/iso"

echo ""
echo "==> ISO built: ${OUTPUT_DIR}/${ISO_NAME}"
ls -lh "${OUTPUT_DIR}/${ISO_NAME}"
echo ""
echo "To write to USB: dd if=${OUTPUT_DIR}/${ISO_NAME} of=/dev/sdX bs=4M status=progress"
