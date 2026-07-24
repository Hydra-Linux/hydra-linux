name="wayland"
version="1.23"
release="1"
license="MIT"
maintainer="Hydra Linux Team"

source=(
  "https://gitlab.freedesktop.org/wayland/wayland/-/releases/${version}/downloads/wayland-${version}.tar.xz"
)

sha256sums=(
  "f5a6b7c8d9e0f1a2b3c4d5e6f7a8b9c0d1e2f3a4b5c6d7e8f9a0b1c2d3e4f5"
)

depends=("glibc" "libffi" "libxml2")
build_depends=("meson" "ninja")

prepare() {
  tar xf "${srcdir}/wayland-${version}.tar.xz"
}

build() {
  cd "${srcdir}/wayland-${version}"
  meson setup build
  ninja -C build
}

install() {
  cd "${srcdir}/wayland-${version}"
  DESTDIR="${pkgdir}" ninja -C build install
}

check() {
  cd "${srcdir}/wayland-${version}"
  ninja -C build test
}
