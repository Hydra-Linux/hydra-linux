name="wireplumber"
version="0.5"
release="1"
license="MIT"
maintainer="Hydra Linux Team"

source=(
  "https://gitlab.freedesktop.org/pipewire/wireplumber/-/archive/${version}/wireplumber-${version}.tar.gz"
)

sha256sums=(
  "a3b4c5d6e7f8a9b0c1d2e3f4a5b6c7d8e9f0a1b2c3d4e5f6a7b8c9d0e1f2a3"
)

depends=("pipewire" "glib" "glibc")
build_depends=("meson" "ninja")

prepare() {
  tar xf "${srcdir}/wireplumber-${version}.tar.gz"
}

build() {
  cd "${srcdir}/wireplumber-${version}"
  meson setup build \
    -Dprefix=/usr \
    -Dbuildtype=release
  ninja -C build
}

install() {
  cd "${srcdir}/wireplumber-${version}"
  DESTDIR="${pkgdir}" ninja -C build install
}

check() {
  cd "${srcdir}/wireplumber-${version}"
  ninja -C build test
}
