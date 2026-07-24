name="plasma-desktop"
version="6.1"
module_deps=("plasma-workspace")

source_url="https://download.kde.org/stable/plasma/${version}/plasma-desktop-${version}.tar.xz"
sha256sum="a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0c1d2e3f4a5b6c7d8e9f0a1"

prepare() {
  tar xf "${srcdir}/plasma-desktop-${version}.tar.xz"
}

build() {
  cd "${srcdir}/plasma-desktop-${version}"
  cmake -B build \
    -DCMAKE_INSTALL_PREFIX=/usr \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_TESTING=OFF
  cmake --build build -j$(nproc)
}

install() {
  cd "${srcdir}/plasma-desktop-${version}"
  DESTDIR="${pkgdir}" cmake --install build
}

check() {
  cd "${srcdir}/plasma-desktop-${version}"
  cmake --build build --target test
}
