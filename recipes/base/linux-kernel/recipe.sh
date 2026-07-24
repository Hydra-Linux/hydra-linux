name="linux-kernel"
version="6.10"
release="1"
license="GPL-2.0-only"
maintainer="Hydra Linux Team"

source=(
  "https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-${version}.tar.xz"
  "https://github.com/zen-kernel/zen-kernel/archive/v${version}-zen1.tar.gz"
)

sha256sums=(
  "627e3797b564b16b0bce2a11fc0f6db05c3f48a1f0766605e3c78d88df6ea708"
  "SKIP"
)

depends=("glibc")
build_depends=("bc" "flex" "bison")

prepare() {
  tar xf "${srcdir}/linux-${version}.tar.xz"
  cd "linux-${version}"
  tar xf "${srcdir}/v${version}-zen1.tar.gz"
  for patch in "${srcdir}/zen-kernel-${version}-zen1"/*.patch; do
    patch -p1 < "$patch"
  done
}

build() {
  cd "${srcdir}/linux-${version}"
  make defconfig
  make -j$(nproc)
}

install() {
  cd "${srcdir}/linux-${version}"
  make modules_install INSTALL_MOD_PATH="${pkgdir}"
  make install INSTALL_PATH="${pkgdir}/boot"
}

check() {
  cd "${srcdir}/linux-${version}"
  make -j$(nproc) scripts/selinux/selinux.h
}
