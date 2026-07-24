#!/bin/bash -e
# Stage 1: Minimal native toolchain (using cross-compiler)
source "$(dirname "$0")/build.env"

echo -e "${YELLOW}[Hydra] Stage 1: Minimal native toolchain${RESET}"

export PATH="$CROSS_TOOLS_DIR/bin:$PATH"
export CC="$TARGET-gcc"
export CXX="$TARGET-g++"

BINUTILS_V=2.42
GCC_V=14.1.0
GLIBC_V=2.39

mkdir -p /tools

echo "Building native binutils..."
cd "$BUILD_DIR"
rm -rf "build-native-binutils"
mkdir build-native-binutils && cd build-native-binutils
tar xf "$SOURCES_DIR/binutils-$BINUTILS_V.tar.xz" --strip-components=1
./configure --prefix=/tools --target=$TARGET --with-sysroot="$SYSROOT" --disable-nls --enable-shared
make -j$JOBS
make install

echo "Building native gcc (core, C only)..."
cd "$BUILD_DIR"
rm -rf "build-native-gcc-core"
mkdir build-native-gcc-core && cd build-native-gcc-core
tar xf "$SOURCES_DIR/gcc-$GCC_V.tar.xz" --strip-components=1
./configure --prefix=/tools --target=$TARGET --with-sysroot="$SYSROOT" \
  --enable-languages=c --disable-nls --disable-multilib
make -j$JOBS all-gcc all-target-libgcc
make install-gcc install-target-libgcc

echo "Building glibc (for /tools)..."
cd "$BUILD_DIR"
rm -rf "build-tools-glibc"
mkdir build-tools-glibc && cd build-tools-glibc
tar xf "$SOURCES_DIR/glibc-$GLIBC_V.tar.xz" --strip-components=1
./configure --prefix=/tools --host=$TARGET --build=$MACHTYPE \
  --with-headers="$SYSROOT/usr/include" --disable-nls --enable-kernel=4.15
make -j$JOBS
make install

echo "Building full gcc (C, C++ for /tools)..."
cd "$BUILD_DIR"
rm -rf "build-native-gcc-full"
mkdir build-native-gcc-full && cd build-native-gcc-full
tar xf "$SOURCES_DIR/gcc-$GCC_V.tar.xz" --strip-components=1
./configure --prefix=/tools --target=$TARGET --with-sysroot=/tools \
  --enable-languages=c,c++ --disable-nls --disable-multilib --enable-shared
make -j$JOBS
make install

echo -e "${GREEN}Stage 1 complete. Native toolchain in /tools${RESET}"
touch /tmp/.hydra-stage1-done
