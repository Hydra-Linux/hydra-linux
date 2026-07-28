name="ninja"
version="1.12.1"
release="1"
license="Apache-2.0"
maintainer="Hydra Linux Team"
source=("https://github.com/ninja-build/ninja/archive/refs/tags/v${version}.tar.gz")
sha256sums=("0000000000000000000000000000000000000000000000000000000000000000")
depends=()
build_depends=("python3")
prepare() { tar xf "${srcdir}/v${version}.tar.gz"; }
build() { cd "${srcdir}/ninja-${version}" && python3 configure.py --bootstrap; }
install() { cd "${srcdir}/ninja-${version}" && cp -a ninja "${pkgdir}/usr/bin/"; }
