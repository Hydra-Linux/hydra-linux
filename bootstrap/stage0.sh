#!/bin/bash -e
# Stage 0: Cross-toolchain bootstrap for Hydra Linux
source "$(dirname "$0")/build.env"

echo -e "${YELLOW}[Hydra] Stage 0: Building cross-toolchain${RESET}"

mkdir -p "$SOURCES_DIR" "$BUILD_DIR" "$CROSS_TOOLS_DIR" "$SYSROOT"

BINUTILS_V=2.42
GCC_V=14.1.0
GLIBC_V=2.39
LINUX_V=6.8

download() {
  local url="$1"
  local file="$SOURCES_DIR/$(basename $url)"
  if [ ! -f "$file" ]; then
    echo "Downloading $url..."
    wget -q "$url" -O "$file"
  fi
}

download "https://ftp.gnu.org/gnu/binutils/binutils-$BINUTILS_V.tar.xz"
download "https://ftp.gnu.org/gnu/gcc/gcc-$GCC_V/gcc-$GCC_V.tar.xz"
download "https://ftp.gnu.org/gnu/glibc/glibc-$GLIBC_V.tar.xz"
download "https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-$LINUX_V.tar.xz"

echo "Installing Linux headers..."
cd "$BUILD_DIR"
rm -rf "linux-$LINUX_V"
tar xf "$SOURCES_DIR/linux-$LINUX_V.tar.xz"
cd "linux-$LINUX_V"
make ARCH=x86_64 INSTALL_HDR_PATH="$SYSROOT/usr" headers_install

echo "Building cross-binutils..."
cd "$BUILD_DIR"
rm -rf "build-binutils"
mkdir build-binutils && cd build-binutils
tar xf "$SOURCES_DIR/binutils-$BINUTILS_V.tar.xz" --strip-components=1
./configure --prefix="$CROSS_TOOLS_DIR" --target=$TARGET --with-sysroot="$SYSROOT" --disable-nls --enable-shared
make -j$JOBS
make install

export PATH="$CROSS_TOOLS_DIR/bin:$PATH"

echo "Building cross-gcc (core)..."
cd "$BUILD_DIR"
rm -rf "build-gcc-core"
mkdir build-gcc-core && cd build-gcc-core
tar xf "$SOURCES_DIR/gcc-$GCC_V.tar.xz" --strip-components=1
./configure --prefix="$CROSS_TOOLS_DIR" --target=$TARGET --with-sysroot="$SYSROOT" \
  --enable-languages=c --disable-nls --disable-multilib
make -j$JOBS all-gcc all-target-libgcc
make install-gcc install-target-libgcc

echo "Building cross-glibc..."
cd "$BUILD_DIR"
rm -rf "build-glibc"
mkdir build-glibc && cd build-glibc
tar xf "$SOURCES_DIR/glibc-$GLIBC_V.tar.xz" --strip-components=1
./configure --prefix="$SYSROOT/usr" --build=$MACHTYPE --host=$TARGET --target=$TARGET \
  --with-headers="$SYSROOT/usr/include" --disable-nls --enable-kernel=4.15
make -j$JOBS
make install

echo "Building full cross-gcc (C, C++)..."
cd "$BUILD_DIR"
rm -rf "build-gcc-full"
mkdir build-gcc-full && cd build-gcc-full
tar xf "$SOURCES_DIR/gcc-$GCC_V.tar.xz" --strip-components=1
./configure --prefix="$CROSS_TOOLS_DIR" --target=$TARGET --with-sysroot="$SYSROOT" \
  --enable-languages=c,c++ --disable-nls --disable-multilib --enable-shared
make -j$JOBS
make install

echo -e "${GREEN}Stage 0 complete. Cross-toolchain at $CROSS_TOOLS_DIR${RESET}"
touch /tmp/.hydra-stage0-done
