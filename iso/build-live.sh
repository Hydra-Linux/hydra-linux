#!/bin/bash -e
# Hydra Linux - Live ISO Builder (OpenRC + KDE Plasma)
# Downloads Arch packages and extracts them manually, excluding systemd

BUILD_BASE="/home/oliwier/hydra-build"
ROOTFS="${BUILD_BASE}/rootfs"
PKG_CACHE="${BUILD_BASE}/pkgcache"
ISODIR="${BUILD_BASE}/iso"
OVERLAY="${BUILD_BASE}/overlay"
FLASH_SRC="/home/oliwier/hydra-linux/flash"
RECIPES="/home/oliwier/hydra-linux/recipes"
PROJECT="/home/oliwier/hydra-linux"
ISO_DATE="$(date +%Y%m%d)"
ISO_NAME="hydra-linux-${ISO_DATE}-x86_64.iso"
LIVE_USER="hydra"

sudo rm -rf "${BUILD_BASE}"
sudo mkdir -p "$ROOTFS" "$PKG_CACHE" "$ISODIR"/{live,boot/grub} "$OVERLAY"
sudo mkdir -p "$OVERLAY/usr/bin" "$OVERLAY/usr/lib/flash/recipes" "$OVERLAY/etc/flash"
sudo chmod 777 "$PKG_CACHE"

# Copy flash and recipes
sudo cp "$FLASH_SRC/flash" "$OVERLAY/usr/bin/flash" && sudo chmod 755 "$OVERLAY/usr/bin/flash"
sudo cp -r "$RECIPES/"* "$OVERLAY/usr/lib/flash/recipes/"

sudo tee "$OVERLAY/etc/flash/flash.conf" > /dev/null << CONF
[paths]
root = "/"
db = "/var/lib/flash/flash.db"
cache = "/var/cache/flash"
build_dir = "/var/cache/flash/build"
recipes_dir = "/usr/lib/flash/recipes"
[repos]
default = "https://github.com/Hydra-Linux/hydra-linux"
CONF

PKGLIST=(
  # Core
  bash coreutils grep sed gawk findutils tar gzip bzip2 xz zstd
  less which file sudo pacman pacman-mirrorlist
  glibc gcc-libs pcre pcre2
  # Init / system (NOT systemd)
  dbus polkit
  # Libraries
  libarchive gpgme sqlite openssl ca-certificates ca-certificates-utils
  zlib libpng freetype2 fontconfig expat archlinux-keyring
  # Networking
  curl wget git openssh networkmanager iwd
  # X11
  xorg-server xorg-xinit xf86-input-libinput xorg-xrandr xorg-xdpyinfo
  mesa mesa-utils libglvnd
  # Wayland
  wayland wayland-utils
  # KDE Plasma
  plasma-desktop plasma-meta plasma-wayland-protocols
  plasma-nm plasma-pa kdeplasma-addons
  sddm sddm-kcm
  dolphin konsole kate gwenview plasma-systemmonitor
  kdegraphics-thumbnailers kdenetwork-filesharing
  breeze breeze-gtk oxygen oxygen-icons
  systemsettings keditbookmarks
  kfind kgpg
  print-manager
  # KDE Graphics
  gwenview spectacle kolourpaint
  # KDE Frameworks
  kconfig kwidgetsaddons kcoreaddons ki18n kiconthemes kio solid kparts
  kpmcore kcrash knewstuff kirigami kirigami-addons kactivitymanagerd
  # Qt
  qt6-base qt6-wayland qt6-svg qt6-declarative qt6-tools
  qt6-virtualkeyboard qt6-webchannel qt6-websockets
  # Audio
  pipewire wireplumber pipewire-pulse pipewire-jack pavucontrol
  # Fonts
  noto-fonts ttf-dejavu ttf-liberation ttf-hack
  # Media
  ffmpegthumbs gst-plugins-base gst-plugins-good
  # Python / Calamares
  python yaml-cpp boost-libs boost
  # System tools
  util-linux less which man-db
  squashfs-tools mtools dosfstools
  ntfs-3g exfatprogs btrfs-progs
  linux-zen mkinitcpio
  # Grub
  grub os-prober
  # Plymouth (boot splash)
  plymouth
)

echo "=== Downloading packages (systemd excluded) ==="
set +e
sudo pacman -Sw --noconfirm \
  --assume-installed=systemd,systemd-libs,systemd-sysvcompat \
  "${PKGLIST[@]}" 2>&1 | grep -v "^error: goal\|^error: target\|^warning:" || true
# Copy freshly downloaded packages to build cache
sudo mkdir -p "$PKG_CACHE"
sudo cp -r /var/cache/pacman/pkg/*.pkg.tar.* "$PKG_CACHE/" 2>/dev/null || true
set -e

echo "=== Extracting packages to rootfs ==="
sudo cp /var/cache/pacman/pkg/*.pkg.tar.* "$PKG_CACHE/" 2>/dev/null || true
for pkg in "$PKG_CACHE"/*.pkg.tar.*; do
  name=$(basename "$pkg" | sed 's/-[0-9].*\.pkg.*//')
  # Skip systemd packages
  case "$name" in
    systemd*|libsystemd*) echo "  SKIP: $name"; continue ;;
  esac
  echo "  $name"
  sudo tar -xpf "$pkg" -C "$ROOTFS" 2>/dev/null || sudo bsdtar -xpf "$pkg" -C "$ROOTFS" 2>/dev/null || true
done

echo "=== Installing OpenRC + elogind (compiled from source) ==="
sudo cp -a /tmp/openrc-build/* "$ROOTFS/" 2>/dev/null || true
sudo cp -a /tmp/elogind-build/* "$ROOTFS/" 2>/dev/null || true
sudo ldconfig -r "$ROOTFS" 2>/dev/null || sudo chroot "$ROOTFS" ldconfig 2>/dev/null || true

# Create necessary directories
sudo mkdir -p "$ROOTFS/etc/init.d" "$ROOTFS/etc/runlevels/default"
sudo mkdir -p "$ROOTFS/etc/runlevels/sysinit" "$ROOTFS/etc/runlevels/boot"
sudo mkdir -p "$ROOTFS/etc/runlevels/shutdown" "$ROOTFS/etc/runlevels/nonetwork"
sudo mkdir -p "$ROOTFS/etc/sudoers.d" "$ROOTFS/etc/sddm.conf.d"

# Cleanup any systemd remnants
sudo rm -rf "$ROOTFS/usr/lib/systemd" "$ROOTFS/etc/systemd" "$ROOTFS/usr/bin/systemd"* 2>/dev/null || true
sudo rm -f "$ROOTFS/usr/lib/tmpfiles.d/systemd.conf" 2>/dev/null || true

echo "=== Configuring OpenRC services ==="
for rl in default sysinit boot shutdown nonetwork; do
  sudo mkdir -p "$ROOTFS/etc/runlevels/$rl"
done

# Enable dbus, networkmanager
sudo ln -sf /etc/init.d/dbus "$ROOTFS/etc/runlevels/default/dbus" 2>/dev/null || true
sudo ln -sf /etc/init.d/networkmanager "$ROOTFS/etc/runlevels/default/networkmanager" 2>/dev/null || true

# SDDM service
cat | sudo tee "$ROOTFS/etc/init.d/sddm" << SDDM
#!/sbin/openrc-run
description="Simple Desktop Display Manager"
depend() { need dbus; }
start() { ebegin "Starting SDDM"; /usr/bin/sddm; eend \$?; }
stop() { ebegin "Stopping SDDM"; killall sddm 2>/dev/null; eend \$?; }
SDDM
sudo chmod +x "$ROOTFS/etc/init.d/sddm"
sudo ln -sf /etc/init.d/sddm "$ROOTFS/etc/runlevels/default/sddm" 2>/dev/null || true

# elogind service
cat | sudo tee "$ROOTFS/etc/init.d/elogind" << ELD
#!/sbin/openrc-run
description="elogind daemon"
depend() { need dbus; }
start() { ebegin "Starting elogind"; /usr/lib/elogind/elogind; eend \$?; }
stop() { ebegin "Stopping elogind"; killall elogind 2>/dev/null; eend \$?; }
ELD
sudo chmod +x "$ROOTFS/etc/init.d/elogind"
sudo ln -sf /etc/init.d/elogind "$ROOTFS/etc/runlevels/default/elogind" 2>/dev/null || true

echo "=== Configuring Plymouth (BGRT boot splash) ==="
sudo mkdir -p "$ROOTFS/etc/plymouth"
cat | sudo tee "$ROOTFS/etc/plymouth/plymouthd.conf" << PLY
[Daemon]
Theme=bgrt
ShowDelay=0
DeviceTimeout=5
PLY

# Plymouth OpenRC service
cat | sudo tee "$ROOTFS/etc/init.d/plymouth" << PLYSRV
#!/sbin/openrc-run
description="Plymouth boot splash"
depend() { after sysfs; }
start() { ebegin "Starting Plymouth"; /usr/bin/plymouthd --attach; eend \$?; }
stop() { ebegin "Stopping Plymouth"; /usr/bin/plymouth --quit; eend \$?; }
PLYSRV
sudo chmod +x "$ROOTFS/etc/init.d/plymouth"
sudo ln -sf /etc/init.d/plymouth "$ROOTFS/etc/runlevels/boot/plymouth" 2>/dev/null || true

echo "=== Setting up live user ==="
echo "root:hydra" | sudo chroot "$ROOTFS" chpasswd 2>/dev/null || true

# Create user manually if useradd not available
sudo mkdir -p "$ROOTFS/home/$LIVE_USER"
grep -q "^$LIVE_USER:" "$ROOTFS/etc/passwd" 2>/dev/null || \
  echo "$LIVE_USER:x:1000:1000:Live User:/home/$LIVE_USER:/bin/bash" | sudo tee -a "$ROOTFS/etc/passwd"
grep -q "^$LIVE_USER:" "$ROOTFS/etc/shadow" 2>/dev/null || \
  echo "$LIVE_USER:!:1000:" | sudo tee -a "$ROOTFS/etc/shadow"
grep -q "^$LIVE_USER:" "$ROOTFS/etc/group" 2>/dev/null || \
  echo "$LIVE_USER:x:1000:$LIVE_USER" | sudo tee -a "$ROOTFS/etc/group"
grep -q "^wheel:" "$ROOTFS/etc/group" 2>/dev/null || \
  echo "wheel:x:10:$LIVE_USER" | sudo tee -a "$ROOTFS/etc/group"

# Modify wheel group
sudo sed -i 's/^wheel:x:10:.*/wheel:x:10:'$LIVE_USER'/' "$ROOTFS/etc/group" 2>/dev/null || true

echo "$LIVE_USER:hydra" | sudo chroot "$ROOTFS" chpasswd 2>/dev/null || true

# sudo
echo "%wheel ALL=(ALL:ALL) NOPASSWD: ALL" | sudo tee "$ROOTFS/etc/sudoers.d/10-wheel" > /dev/null

echo "hydra-linux" | sudo tee "$ROOTFS/etc/hostname"

# SDDM autologin with branding
sudo mkdir -p "$ROOTFS/etc/sddm.conf.d" "$ROOTFS/usr/share/sddm/themes/hydra"
if [ -f "$PROJECT/iso/splash/hydra-logo.png" ]; then
  sudo cp "$PROJECT/iso/splash/hydra-logo.png" "$ROOTFS/usr/share/sddm/themes/hydra/"
fi
cat | sudo tee "$ROOTFS/etc/sddm.conf.d/autologin.conf" << SDDMCFG
[Autologin]
User=$LIVE_USER
Session=plasma.desktop
Relogin=false
[Theme]
Current=hydra
[General]
HaltCommand=/sbin/openrc-shutdown poweroff
RebootCommand=/sbin/openrc-shutdown reboot
SDDMCFG

# KDE Plasma desktop wallpaper
if [ -f "$PROJECT/iso/splash/hydra-logo.png" ]; then
  sudo mkdir -p "$ROOTFS/usr/share/wallpapers/hydra/contents/images"
  sudo cp "$PROJECT/iso/splash/hydra-logo.png" "$ROOTFS/usr/share/wallpapers/hydra/contents/images/"
  sudo mkdir -p "$ROOTFS/home/$LIVE_USER/.config"
  cat | sudo tee "$ROOTFS/home/$LIVE_USER/.config/plasma-org.kde.plasma.desktop-appletsrc" << WALL
[Containments][2][Wallpaper][org.kde.image][General]
Image=file:///usr/share/wallpapers/hydra/contents/images/hydra-logo.png
WALL
  sudo chown -R 1000:1000 "$ROOTFS/home/$LIVE_USER/.config" 2>/dev/null || true
fi

# MOTD with ASCII art
cat | sudo tee "$ROOTFS/etc/motd" << 'MOTD'
[34m
                                              +++++++++
                                ++++++        +++  +++++++
                                +++++++++   +++    ++  +++++
                              +++++ ++++++++++  ++++++++++++
                             +++   ++    ++++  +++   +
                            +++  ++++++++++++ +++
                            +++ +++        ++  ++     +++++++++
                            +++ +++        ++  +++  +++++ ++++++++
                            +++  ++++      +++  ++++++          +++
                             ++++  +++++    +++  +++++ ++++++++++++
                               ++++   +++++  ++++ +++++++
                                 +++++   ++++  +++  ++++
                      +++++        ++++++  ++++ +++   +++
                    ++++++++++         ++++  +++ +++   +++
                   ++++++++ +++          ++   +++ +++   +++
                   +++++ +++ +++    ++++++++   ++++++   +++
                   +++ ++++  +++ ++++++  ++     +++++    +++
                      +++   +++ +++                      +++
                   +++++  ++++ +++     +++              +++
                  +++   +++   +++   +++++++++     +     +++
              -  +++   +++   +++   +++     +++   +++   +++
                 +++  +++   +++   +++  +++++++  +++  ++++
                 +++   +++++++    ++ +++   +++  +++++++++
                 +++     ++      ++++++    ++  +++++++ +++
                  ++++         +++++++    +++ +++   +++ +++
                    ++++++++++++++++       +++ +++++ +++ +++++++
                       +++++++             ++++++++++ +++++++++++

[33m                      Many heads. One system.
                      Hydra Linux Live - $(uname -r)

                      Commands:
                        flash install <pkg>    Build & install package
                        flash list             List installed packages
                        calamares              Start the installer

                      To install: click Install Hydra Linux on the desktop
MOTD

# Profile
cat | sudo tee "$ROOTFS/etc/profile" << PROF
export PATH="/usr/local/bin:/usr/bin:/bin:/usr/local/sbin:/usr/sbin:/sbin"
export EDITOR="vim"
cat /etc/motd
PROF

echo "=== Installing Calamares ==="
if [ -f /usr/bin/calamares ]; then
  sudo cp /usr/bin/calamares "$ROOTFS/usr/bin/" 2>/dev/null || true
  for f in /usr/lib/libcalamares* /usr/lib/calamares; do
    sudo cp -r "$f" "$ROOTFS/usr/lib/" 2>/dev/null || true
  done
fi

# Desktop shortcuts
sudo mkdir -p "$ROOTFS/home/$LIVE_USER/.config/autostart" "$ROOTFS/home/$LIVE_USER/Desktop"
cat | sudo tee "$ROOTFS/home/$LIVE_USER/.config/autostart/calamares.desktop" << CALA
[Desktop Entry]
Type=Application
Name=Install Hydra Linux
Exec=calamares
Icon=system-software-install
Terminal=false
X-KDE-autostart-phase=2
CALA

cat | sudo tee "$ROOTFS/home/$LIVE_USER/Desktop/install-hydra.desktop" << CALA2
[Desktop Entry]
Type=Application
Name=Install Hydra Linux
Exec=calamares
Icon=drive-harddisk
Terminal=false
Categories=System;
CALA2

sudo chown -R 1000:1000 "$ROOTFS/home/$LIVE_USER" 2>/dev/null || true

# Calamares config
sudo mkdir -p "$ROOTFS/etc/calamares/modules"
cat | sudo tee "$ROOTFS/etc/calamares/settings.conf" << CALSET
---
modules-search: [ /etc/calamares/modules ]
sequence:
- branding:
  - welcome
- partition:
  - partition
- filesystem:
  - unpackfs
  - mount
- install:
  - users
  - displaymanager
  - networkcfg
  - grubcfg
  - bootloader
  - fstab
  - locale
  - keyboard
  - machineid
- postinstall:
  - finished
branding: hydra
prompt-install: true
CALSET

sudo mkdir -p "$ROOTFS/etc/calamares/branding/hydra"
if [ -f "$PROJECT/iso/splash/hydra-logo.png" ]; then
  sudo cp "$PROJECT/iso/splash/hydra-logo.png" "$ROOTFS/etc/calamares/branding/hydra/logo.png"
fi
cat | sudo tee "$ROOTFS/etc/calamares/branding/hydra/branding.desc" << BRAND
---
branding:
  productName: "Hydra Linux"
  shortProductName: "Hydra"
  version: "$ISO_DATE"
  shortVersion: "rolling"
  versionedName: "Hydra Linux Rolling"
  bootloaderEntryName: "Hydra Linux"
  productUrl: "https://hydra-linux.org"
  supportUrl: "https://github.com/Hydra-Linux/hydra-linux"
  welcomeMessage: "Welcome to Hydra Linux.\n\nMany heads. One system."
  logo: "logo.png"
BRAND

echo "=== Copy overlay ==="
sudo cp -r "$OVERLAY/"* "$ROOTFS/" 2>/dev/null || true

echo "=== Create SquashFS ==="
sudo mksquashfs "$ROOTFS" "$ISODIR/live/hydra-root.squashfs" \
  -comp zstd -b 1M -noappend \
  -e boot dev proc sys run tmp mnt var/cache/pacman var/tmp \
  2>&1 | tail -3

echo "=== Kernel + initramfs ==="
# Find the kernel - it's at /usr/lib/modules/<version>/vmlinuz on Arch
KERNEL_FILE=$(find "$ROOTFS/usr/lib/modules" -name vmlinuz 2>/dev/null | head -1)
if [ -n "$KERNEL_FILE" ]; then
  sudo cp "$KERNEL_FILE" "$ISODIR/boot/vmlinuz"
  echo "  kernel: $KERNEL_FILE"
else
  # Fallback: check /boot
  sudo cp "$ROOTFS/boot/vmlinuz-linux-zen" "$ISODIR/boot/vmlinuz" 2>/dev/null || true
  sudo cp "$ROOTFS/boot/vmlinuz-"* "$ISODIR/boot/vmlinuz" 2>/dev/null || true
fi

IDIR="${BUILD_BASE}/initramfs"
sudo rm -rf "$IDIR" && mkdir -p "$IDIR"/{bin,proc,sys,dev}
sudo cp "$ROOTFS/usr/bin/bash" "$ROOTFS/usr/bin/mount" "$ROOTFS/usr/bin/umount" \
     "$ROOTFS/usr/bin/mkdir" "$ROOTFS/usr/bin/grep" "$ROOTFS/usr/bin/sleep" "$IDIR/bin/" 2>/dev/null
sudo cp "$ROOTFS/usr/sbin/switch_root" "$IDIR/bin/" 2>/dev/null || true
sudo ln -sf /bin/bash "$IDIR/bin/sh"

cat | sudo tee "$IDIR/init" << INIT
#!/bin/sh
/bin/mount -t proc proc /proc
/bin/mount -t sysfs sysfs /sys
/bin/mount -t devtmpfs devtmpfs /dev
/bin/mkdir -p /media
/bin/mount -t iso9660 /dev/sr0 /media 2>/dev/null || /bin/mount -t vfat /dev/sr0 /media 2>/dev/null || true
if [ -f /media/live/hydra-root.squashfs ]; then
  /bin/mkdir -p /newroot
  /bin/mount -t squashfs -o loop /media/live/hydra-root.squashfs /newroot
  exec /bin/switch_root /newroot /sbin/openrc-init
fi
exec /bin/sh
INIT
sudo chmod +x "$IDIR/init"

cd "$IDIR" && sudo find . | sudo cpio -o -H newc | zstd -f > "$ISODIR/boot/initramfs.img" 2>/dev/null

echo "=== GRUB ==="
# Copy splash image
sudo mkdir -p "$ISODIR/boot/grub/themes/hydra"
if [ -f "$PROJECT/iso/splash/hydra-logo.png" ]; then
  sudo cp "$PROJECT/iso/splash/hydra-logo.png" "$ISODIR/boot/grub/themes/hydra/"
fi

cat | sudo tee "$ISODIR/boot/grub/grub.cfg" << GRUB
set default=0
set timeout=5
set gfxmode=1920x1080
set gfxpayload=keep
terminal_output gfxterm

if loadfont unicode; then
  if [ -f /boot/grub/themes/hydra/hydra-logo.png ]; then
    background_image /boot/grub/themes/hydra/hydra-logo.png
  fi
fi

menuentry "Hydra Linux (KDE Plasma + OpenRC)" {
  linux /boot/vmlinuz quiet splash
  initrd /boot/initramfs.img
}

menuentry "Hydra Linux - Safe Mode" {
  linux /boot/vmlinuz nomodeset
  initrd /boot/initramfs.img
}

menuentry "Shutdown" {
  halt
}

menuentry "Reboot" {
  reboot
}
GRUB

echo "=== Build ISO ==="
sudo chmod 644 "$ISODIR/boot/vmlinuz" "$ISODIR/boot/initramfs.img" "$ISODIR/boot/grub/grub.cfg" 2>/dev/null
sudo chmod 644 "$ISODIR/live/hydra-root.squashfs" 2>/dev/null

cd "$PROJECT" && rm -f "$ISO_NAME"
sudo grub-mkrescue -o "$ISO_NAME" "$ISODIR" \
  -- -volid "HYDRA_LINUX" -iso-level 3 -full-iso9660-filenames 2>&1 | grep -v "^libisofs: WARNING\|^xorriso"

sudo chown "$USER:$USER" "$ISO_NAME" 2>/dev/null

echo ""
echo "=== Build Complete ==="
ls -lh "$PROJECT/$ISO_NAME"
echo "Rootfs: $(sudo du -sh $ROOTFS 2>/dev/null | awk '{print $1}')"
echo "Packages downloaded: $(ls $PKG_CACHE/*.pkg.tar.* 2>/dev/null | wc -l)"
