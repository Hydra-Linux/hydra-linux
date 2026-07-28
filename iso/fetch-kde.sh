#!/bin/bash -e
# Hydra Linux - KDE Plasma 6 Binary Bootstrap for Live ISO
# Downloads prebuilt KDE + Qt6 + display deps from Arch Linux repos
# Extracts directly to iso/overlay/ for the live ISO
#
# Usage: ./iso/fetch-kde.sh

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
OVERLAY="${PROJECT_DIR}/iso/overlay"
CACHE_DIR="${PROJECT_DIR}/build/pkgcache"
ARCH_PKGS="${CACHE_DIR}/arch-pkgs"

MIRROR="https://geo.mirror.pkgbuild.com"
REPOS=("core" "extra" "community")

mkdir -p "$OVERLAY" "$ARCH_PKGS"

# ---- Resolve package filenames from repo databases ----
resolve_filename() {
  local pkgname="$1"
  # Check local cache first
  local cache_file="$ARCH_PKGS/.names"
  if [ -f "$cache_file" ]; then
    local found
    found=$(grep "^${pkgname}:" "$cache_file" 2>/dev/null | cut -d: -f2)
    if [ -n "$found" ]; then
      echo "$found"
      return 0
    fi
  fi
  return 1
}

build_name_cache() {
  local cache_file="$ARCH_PKGS/.names"
  [ -f "$cache_file" ] && return 0

  echo "Building package name cache from Arch repos..."
  mkdir -p "${ARCH_PKGS}/db"

  for repo in "${REPOS[@]}"; do
    local db_file="${ARCH_PKGS}/db/${repo}.db"
    local url="${MIRROR}/${repo}/os/x86_64/${repo}.db.tar.zst"

    if [ ! -f "${db_file}.tar.zst" ]; then
      echo "  Downloading ${repo} database..."
      curl -sfL "$url" -o "${db_file}.tar.zst" || continue
    fi

    # Extract just the desc files
    tar --zstd -xf "${db_file}.tar.zst" \
      -C "${ARCH_PKGS}/db" \
      "*/desc" 2>/dev/null || true

    # Parse desc files
    for desc in "${ARCH_PKGS}/db"/*/desc; do
      [ -f "$desc" ] || continue
      local name=""
      local filename=""
      while IFS= read -r line; do
        if [ "$line" = "%NAME%" ]; then
          IFS= read -r name
        elif [ "$line" = "%FILENAME%" ]; then
          IFS= read -r filename
        fi
      done < "$desc"
      if [ -n "$name" ] && [ -n "$filename" ]; then
        echo "${name}:${filename}" >> "$cache_file"
      fi
    done
  done
  echo "  Cached $(wc -l < "$cache_file") package names"
}

# ---- Download a package ----
download_pkg() {
  local pkgname="$1"
  local dest="$ARCH_PKGS"

  # Check if already downloaded
  if ls "$dest/${pkgname}"-*.pkg.tar.zst 1>/dev/null 2>&1; then
    return 0
  fi

  # Resolve exact filename
  local filename
  filename=$(resolve_filename "$pkgname")
  if [ -z "$filename" ]; then
    echo "  [SKIP]  $pkgname (not found in repos)"
    return 1
  fi

  # Try each repo
  for repo in "${REPOS[@]}"; do
    local url="${MIRROR}/${repo}/os/x86_64/${filename}"
    echo "  [fetch] $pkgname ($filename)"
    if curl -sfL "$url" -o "$dest/$filename" 2>/dev/null; then
      return 0
    fi
  done

  echo "  [FAIL]  $pkgname"
  return 1
}

# ---- Package lists ----

DISPLAY_DEPS=(
  # Wayland core
  wayland wayland-protocols libdrm libglvnd mesa
  # X11
  xorg-server xorg-xwayland xorg-xauth xkeyboard-config
  libx11 libxext libxfixes libxi libxrandr libxrender
  libxshmfence libxxf86vm libxcb xcb-proto
  # Graphics libs
  libpng libjpeg-turbo libwebp giflib pixman
  freetype2 fontconfig harfbuzz cairo pango
  # Input
  libinput evdev mtdev libwacom
  # Acceleration
  libva libvdpau
)

FONTS=(
  ttf-dejavu ttf-liberation noto-fonts
)

QT6_DEPS=(
  qt6-base qt6-declarative qt6-svg qt6-wayland qt6-shadertools
  qt6-tools qt6-5compat qt6-speech
)

KF6_DEPS=(
  kconfig kcoreaddons kguiaddons ki18n kwidgetsaddons kwindowsystem
  kiconthemes knotifications kxmlgui kdbusaddons kio solid sonnet
  kcrash karchive kservice ktextwidgets kglobalaccel kcompletion
  kjobwidgets kitemviews kbookmarks kcodecs kconfigwidgets
  kdeclarative kded kdesu kemoticons kfilemetadata
  kimageformats knotifyconfig kparts kplotting kpty krunner
  kscreen ktexteditor kwallet kwayland breeze-icons
  kunitconversion kuserfeedback baloo
)

PLASMA_DEPS=(
  plasma-workspace kwin plasma-desktop plasma-pa plasma-nm
  bluedevil powerdevil systemsettings kscreen khotkeys
  kinfocenter kmenuedit milou oxygen breeze breeze-gtk
  kdecoration kscreenlocker kwallet-pam kwayland-integration
  libkscreen libksysguard libplasma plasma-integration
  plasma-systemmonitor plasma-disks
)

APPS=(
  konsole dolphin kate gwenview kdialog kwrite
  okular spectacle kcalc ark
)

MISC_DEPS=(
  sddm polkit-kde-agent xdg-desktop-portal xdg-desktop-portal-kde
  accountservice udisks2 upower gtk3 phonon-qt6 phonon-qt6-vlc
  gst-plugins-base pipewire-jack pipewire-alsa
  network-manager-applet
)

# ---- Main ----
echo "=== KDE Plasma 6 Binary Bootstrap ==="
build_name_cache

ALL_PKGS=()
for _g in "${DISPLAY_DEPS[@]}" "${FONTS[@]}" "${QT6_DEPS[@]}" \
          "${KF6_DEPS[@]}" "${PLASMA_DEPS[@]}" "${APPS[@]}" "${MISC_DEPS[@]}"; do
  ALL_PKGS+=("$_g")
done
ALL_PKGS=($(printf "%s\n" "${ALL_PKGS[@]}" | sort -u))

echo "Packages to fetch: ${#ALL_PKGS[@]}"
echo ""

for pkg in "${ALL_PKGS[@]}"; do
  download_pkg "$pkg"
done

echo ""
echo "Extracting to overlay..."
for f in "$ARCH_PKGS"/*.pkg.tar.zst; do
  [ -f "$f" ] || continue
  name=$(basename "$f" | sed -n 's/\(.*\)-[0-9].*/\1/p')
  echo "  [extract] $name"
  tar xf "$f" -C "$OVERLAY" 2>/dev/null || true
done

echo ""
echo "Running post-install scripts..."
find "$OVERLAY" -name ".INSTALL" 2>/dev/null | while read -r inst; do
  echo "  [post] $(basename $(dirname "$inst"))"
  (cd "$OVERLAY" && bash -c "source '$inst'; post_install 2>/dev/null" 2>/dev/null) || true
done

echo ""
echo "=== KDE binary bootstrap complete ==="
echo "Packages extracted to: $OVERLAY"
echo "Total size: $(du -sh "$OVERLAY" 2>/dev/null | cut -f1)"
