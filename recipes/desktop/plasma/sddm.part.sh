name="sddm"
version="6.1"
module_deps=()

source_url="https://github.com/sddm/sddm/archive/v${version}.tar.gz"
sha256sum="d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0c1d2e3f4a5b6c7d8e9f0a1b2c3d4"

prepare() {
  tar xf "${srcdir}/v${version}.tar.gz"
}

build() {
  cd "${srcdir}/sddm-${version}"
  cmake -B build \
    -DCMAKE_INSTALL_PREFIX=/usr \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_TESTING=OFF \
    -DNO_SYSTEMD=ON \
    -DUSE_OPENRC=ON
  cmake --build build -j$(nproc)
}

install() {
  cd "${srcdir}/sddm-${version}"
  DESTDIR="${pkgdir}" cmake --install build
}

check() {
  cd "${srcdir}/sddm-${version}"
  cmake --build build --target test
}
