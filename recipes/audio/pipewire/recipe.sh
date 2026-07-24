name="pipewire"
version="1.2"
release="1"
license="MIT"
maintainer="Hydra Linux Team"

source=(
  "https://gitlab.freedesktop.org/pipewire/pipewire/-/archive/${version}/pipewire-${version}.tar.gz"
)

sha256sums=(
  "f2a3b4c5d6e7f8a9b0c1d2e3f4a5b6c7d8e9f0a1b2c3d4e5f6a7b8c9d0e1f2"
)

depends=("glibc" "alsa-lib" "dbus" "glib")
build_depends=("meson" "ninja")

prepare() {
  tar xf "${srcdir}/pipewire-${version}.tar.gz"
}

build() {
  cd "${srcdir}/pipewire-${version}"
  meson setup build \
    -Dpipewire-jack=enabled \
    -Dpipewire-pulseaudio=enabled \
    -Dpipewire-alsa=enabled \
    -Dexamples=false \
    -Dtests=false
  ninja -C build
}

install() {
  cd "${srcdir}/pipewire-${version}"
  DESTDIR="${pkgdir}" ninja -C build install
}

check() {
  cd "${srcdir}/pipewire-${version}"
  ninja -C build test
}
