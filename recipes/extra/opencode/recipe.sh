name="opencode"
version="0.1.0"
release="1"
license="MIT"
maintainer="Hydra Linux Team"

source=(
  "https://github.com/anomalyco/opencode/archive/refs/tags/v${version}.tar.gz"
)

sha256sums=(
  "0000000000000000000000000000000000000000000000000000000000000000"
)

depends=("glibc")
build_depends=("go")

build() {
  cd "${srcdir}/opencode-${version}"
  go build -o opencode .
}

install() {
  mkdir -p "${pkgdir}/usr/bin"
  cp "${srcdir}/opencode-${version}/opencode" "${pkgdir}/usr/bin/"
  chmod 755 "${pkgdir}/usr/bin/opencode"
}
