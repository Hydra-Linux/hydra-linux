name="mesa"
version="24.1"
release="1"
license="MIT"
maintainer="Hydra Linux Team"

source=(
  "https://archive.mesa3d.org/mesa-${version}.tar.xz"
)

sha256sums=(
  "e4f5a6b7c8d9e0f1a2b3c4d5e6f7a8b9c0d1e2f3a4b5c6d7e8f9a0b1c2d3e4"
)

depends=("glibc" "libdrm" "libx11" "wayland")
build_depends=("python" "meson" "ninja")

prepare() {
  tar xf "${srcdir}/mesa-${version}.tar.xz"
}

build() {
  cd "${srcdir}/mesa-${version}"
  meson setup build \
    -Dgallium-drivers=auto \
    -Dvulkan-drivers=auto \
    -Degl=enabled \
    -Dgbm=enabled \
    -Dopengl=true
  ninja -C build
}

install() {
  cd "${srcdir}/mesa-${version}"
  DESTDIR="${pkgdir}" ninja -C build install
}

check() {
  cd "${srcdir}/mesa-${version}"
  ninja -C build test
}
