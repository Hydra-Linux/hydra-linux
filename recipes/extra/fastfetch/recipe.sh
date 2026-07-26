name="fastfetch"
version="2.24.0"
release="1"
license="MIT"
maintainer="Hydra Linux Team"

source=(
  "https://github.com/fastfetch-cli/fastfetch/releases/download/${version}/fastfetch-${version}.tar.gz"
)

sha256sums=(
  "0000000000000000000000000000000000000000000000000000000000000000"
)

depends=("glibc")
build_depends=("cmake" "pkgconf")

build() {
  cd "${srcdir}/fastfetch-${version}"
  cmake -B build -DCMAKE_INSTALL_PREFIX=/usr
  cmake --build build -j$(nproc)
}

install() {
  cd "${srcdir}/fastfetch-${version}"
  DESTDIR="${pkgdir}" cmake --install build
}
