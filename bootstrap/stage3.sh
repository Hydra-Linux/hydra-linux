#!/bin/bash -e
# Stage 3: Base system userspace
source "$(dirname "$0")/build.env"

echo -e "${YELLOW}[Hydra] Stage 3: Building base system${RESET}"

if [ "$EUID" -ne 0 ]; then echo "Please run as root"; exit 1; fi

export PATH="/usr/bin:/bin:/usr/sbin:/sbin:$PATH"

mkdir -p /{dev,etc,home,proc,sys,var/{cache,lib,log,spool},tmp}
mount -t proc /proc /proc 2>/dev/null || true
mount -t sysfs /sys /sys 2>/dev/null || true

build_pkg() {
  local name=$1 version=$2 url=$3
  local dir="$BUILD_DIR/$name-$version"
  cd "$BUILD_DIR"
  rm -rf "$dir"
  if [ ! -f "$SOURCES_DIR/$(basename $url)" ]; then
    wget -q "$url" -O "$SOURCES_DIR/$(basename $url)"
  fi
  tar xf "$SOURCES_DIR/$(basename $url)" -C "$BUILD_DIR"
  mv "$BUILD_DIR/$(basename $url .tar.*)" "$dir" 2>/dev/null || true
  cd "$dir"
}

# Linux headers
build_pkg "linux" "6.8" "https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-6.8.tar.xz"
make ARCH=x86_64 INSTALL_HDR_PATH=/usr headers_install

# Util-linux
build_pkg "util-linux" "2.40" "https://www.kernel.org/pub/linux/utils/util-linux/v2.40/util-linux-2.40.tar.xz"
./configure --prefix=/usr --disable-chfn-chsh --disable-login --disable-nologin --disable-su \
  --disable-setpriv --disable-runuser --disable-makeinstall-chown --disable-systemd
make -j$JOBS
make install

# Coreutils
build_pkg "coreutils" "9.5" "https://ftp.gnu.org/gnu/coreutils/coreutils-9.5.tar.xz"
./configure --prefix=/usr
make -j$JOBS
make install

# Bash
build_pkg "bash" "5.2.32" "https://ftp.gnu.org/gnu/bash/bash-5.2.32.tar.gz"
./configure --prefix=/usr
make -j$JOBS
make install

# Make
build_pkg "make" "4.4.1" "https://ftp.gnu.org/gnu/make/make-4.4.1.tar.gz"
./configure --prefix=/usr
make -j$JOBS
make install

# Gawk, grep, sed
for pkg in gawk-5.3.0 grep-3.11 sed-4.9; do
  name=${pkg%-*}
  baseurl="https://ftp.gnu.org/gnu/$name"
  case $name in
    gawk) baseurl="https://ftp.gnu.org/gnu/gawk" ;;
  esac
  build_pkg "$name" "${pkg#*-}" "$baseurl/$pkg.tar.xz"
  ./configure --prefix=/usr
  make -j$JOBS
  make install
done

# OpenRC init
build_pkg "openrc" "0.55" "https://github.com/OpenRC/openrc/archive/refs/tags/0.55.tar.gz"
meson setup build
ninja -C build
DESTDIR=/ ninja -C build install

# Zlib, libarchive, sqlite (flash deps)
build_pkg "zlib" "1.3.1" "https://zlib.net/zlib-1.3.1.tar.gz"
./configure --prefix=/usr
make -j$JOBS
make install

build_pkg "sqlite" "346" "https://www.sqlite.org/2024/sqlite-autoconf-3460000.tar.gz"
./configure --prefix=/usr
make -j$JOBS
make install

echo -e "${GREEN}Stage 3 complete. Base system installed.${RESET}"
touch /tmp/.hydra-stage3-done
