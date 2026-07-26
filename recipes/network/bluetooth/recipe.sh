name="bluetooth"
version="5.77"
release="1"
license="LGPL-2.1-only"
maintainer="Hydra Linux Team"

source=(
  "https://www.kernel.org/pub/linux/bluetooth/bluez-${version}.tar.xz"
)

sha256sums=(
  "0000000000000000000000000000000000000000000000000000000000000000"
)

depends=("glibc" "dbus" "libical" "readline")
build_depends=("make" "pkgconf")

build() {
  cd "${srcdir}/bluez-${version}"
  ./configure --prefix=/usr --enable-library
  make -j$(nproc)
}

install() {
  cd "${srcdir}/bluez-${version}"
  make DESTDIR="${pkgdir}" install
}
