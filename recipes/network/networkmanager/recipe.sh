name="networkmanager"
version="1.50"
release="1"
license="GPL-2.0-only"
maintainer="Hydra Linux Team"

source=(
  "https://download.gnome.org/sources/NetworkManager/${version%.*}/NetworkManager-${version}.tar.xz"
)

sha256sums=(
  "b8c9d0e1f2a3b4c5d6e7f8a9b0c1d2e3f4a5b6c7d8e9f0a1b2c3d4e5f6a7b8"
)

depends=("glibc" "systemd-libs" "glib" "libnl" "curl" "iwd")
build_depends=("meson" "ninja" "python")

prepare() {
  tar xf "${srcdir}/NetworkManager-${version}.tar.xz"
}

build() {
  cd "${srcdir}/NetworkManager-${version}"
  meson setup build \
    -Diwd=true \
    -Dsystemd=false \
    -Dopenrc=true \
    -Dcrypto=gnutls \
    -Dmodem_manager=false \
    -Dbluez5=false \
    -Dnmtui=true \
    -Dnmcli=true \
    -Dconfig_plugins_default=keyfile
  ninja -C build
}

install() {
  cd "${srcdir}/NetworkManager-${version}"
  DESTDIR="${pkgdir}" ninja -C build install
}

check() {
  cd "${srcdir}/NetworkManager-${version}"
  ninja -C build test
}
