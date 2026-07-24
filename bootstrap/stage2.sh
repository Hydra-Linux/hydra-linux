#!/bin/bash -e
# Stage 2: Final native toolchain (built with /tools compiler)
source "$(dirname "$0")/build.env"

echo -e "${YELLOW}[Hydra] Stage 2: Final native toolchain${RESET}"

export PATH="/tools/bin:$PATH"
export CC="gcc"
export CXX="g++"

BINUTILS_V=2.42
GCC_V=14.1.0
GLIBC_V=2.39

echo "Building final binutils..."
cd "$BUILD_DIR"
rm -rf "build-final-binutils"
mkdir build-final-binutils && cd build-final-binutils
tar xf "$SOURCES_DIR/binutils-$BINUTILS_V.tar.xz" --strip-components=1
./configure --prefix=/usr --disable-nls --enable-shared --enable-gold --enable-ld=default
make -j$JOBS
make install

echo "Building final gcc (pass 1, C only)..."
cd "$BUILD_DIR"
rm -rf "build-final-gcc-p1"
mkdir build-final-gcc-p1 && cd build-final-gcc-p1
tar xf "$SOURCES_DIR/gcc-$GCC_V.tar.xz" --strip-components=1
./configure --prefix=/usr --enable-languages=c,c++ --disable-nls --disable-multilib --enable-shared
make -j$JOBS all-gcc all-target-libgcc
make install-gcc install-target-libgcc

echo "Building final glibc..."
cd "$BUILD_DIR"
rm -rf "build-final-glibc"
mkdir build-final-glibc && cd build-final-glibc
tar xf "$SOURCES_DIR/glibc-$GLIBC_V.tar.xz" --strip-components=1
./configure --prefix=/usr --disable-nls --enable-kernel=4.15
make -j$JOBS
make install

echo "Building final gcc (pass 2, full)..."
cd "$BUILD_DIR"
rm -rf "build-final-gcc-p2"
mkdir build-final-gcc-p2 && cd build-final-gcc-p2
tar xf "$SOURCES_DIR/gcc-$GCC_V.tar.xz" --strip-components=1
./configure --prefix=/usr --enable-languages=c,c++ --disable-nls --disable-multilib --enable-shared
make -j$JOBS
make install

echo -e "${GREEN}Stage 2 complete. Final toolchain in /usr${RESET}"
touch /tmp/.hydra-stage2-done
