name="linux"
version="6.11"
release="1"
license="GPL-2.0-only"
maintainer="Hydra Linux Team"

source=(
  "https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-${version}.tar.xz"
)

sha256sums=(
  "0000000000000000000000000000000000000000000000000000000000000000"
)

depends=()
build_depends=("bc" "rsync" "cpio")

prepare() {
  tar xf "${srcdir}/linux-${version}.tar.xz"
  cp "${scriptdir}/config" "${srcdir}/linux-${version}/.config"
}

build() {
  cd "${srcdir}/linux-${version}"
  make -j$(nproc)
}

install() {
  cd "${srcdir}/linux-${version}"
  make INSTALL_MOD_PATH="${pkgdir}" modules_install
  make INSTALL_PATH="${pkgdir}/boot" install
}
