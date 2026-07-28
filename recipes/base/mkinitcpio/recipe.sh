name="mkinitcpio"
version="38"
release="1"
license="GPL-2.0-only"
maintainer="Hydra Linux Team"
source=("https://gitlab.archlinux.org/mkinitcpio/mkinitcpio/-/archive/v${version}/mkinitcpio-v${version}.tar.gz")
sha256sums=("0000000000000000000000000000000000000000000000000000000000000000")
depends=("bash" "busybox" "kmod" "coreutils")
build_depends=()
prepare() { tar xf "${srcdir}/mkinitcpio-v${version}.tar.gz"; }
build() { echo "mkinitcpio is a shell script, nothing to build"; }
install() { cd "${srcdir}/mkinitcpio-v${version}" && make DESTDIR="${pkgdir}" install; }
