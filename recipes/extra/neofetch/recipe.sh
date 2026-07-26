name="neofetch"
version="7.1.0"
release="1"
license="MIT"
maintainer="Hydra Linux Team"

source=(
  "https://github.com/dylanaraps/neofetch/archive/refs/tags/${version}.tar.gz"
)

sha256sums=(
  "0000000000000000000000000000000000000000000000000000000000000000"
)

depends=("bash")
build_depends=()

install() {
  mkdir -p "${pkgdir}/usr/bin"
  cp "${srcdir}/neofetch-${version}/neofetch" "${pkgdir}/usr/bin/"
  chmod 755 "${pkgdir}/usr/bin/neofetch"
}
