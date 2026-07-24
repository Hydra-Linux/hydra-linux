name="kwin"
version="6.1"
module_deps=("plasma-workspace")

source_url="https://download.kde.org/stable/plasma/${version}/kwin-${version}.tar.xz"
sha256sum="c3d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0c1d2e3f4a5b6c7d8e9f0a1b2c3"

prepare() {
  tar xf "${srcdir}/kwin-${version}.tar.xz"
}

build() {
  cd "${srcdir}/kwin-${version}"
  cmake -B build \
    -DCMAKE_INSTALL_PREFIX=/usr \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_TESTING=OFF \
    -DKWIN_BUILD_SCREENLOCKER=ON
  cmake --build build -j$(nproc)
}

install() {
  cd "${srcdir}/kwin-${version}"
  DESTDIR="${pkgdir}" cmake --install build
}

check() {
  cd "${srcdir}/kwin-${version}"
  cmake --build build --target test
}
