name="systemd-libs"
version="255"
release="1"
license="LGPL-2.1-only"
maintainer="Hydra Linux Team"

source=(
  "https://github.com/systemd/systemd/archive/v${version}.tar.gz"
)

sha256sums=(
  "d3e4f5a6b7c8d9e0f1a2b3c4d5e6f7a8b9c0d1e2f3a4b5c6d7e8f9a0b1c2d3"
)

depends=("glibc" "libcap")
build_depends=("meson" "ninja")

prepare() {
  tar xf "${srcdir}/v${version}.tar.gz"
}

build() {
  cd "${srcdir}/systemd-${version}"
  meson setup build \
    -Dsystemd=false \
    -Dlink-udev-shared=false \
    -Dlink-systemd-shared=false \
    -Dnss-systemd=false \
    -Dnss-resolve=false \
    -Dnss-myhostname=false \
    -Dnss-mymachines=false \
    -Dhomectl=false \
    -Dportabled=false \
    -Duserdb=false \
    -Dnetworkd=false \
    -Dresolve=false \
    -Dcoredump=false \
    -Dlogind=false \
    -Dhostnamed=false \
    -Dtimedated=false \
    -Dtimesyncd=false \
    -Dlocaled=false \
    -Dnspawn=false \
    -Dstandalone-binaries=false \
    -Dtests=false \
    -Ddbus=false \
    -Dman=false \
    -Dhibernate=false \
    -Dlibcryptsetup=false \
    -Dlibidn=false \
    -Dlibidn2=false \
    -Dfirstboot=false \
    -Dsysusers=false \
    -Dtmpfiles=false \
    -Dsysctl=false \
    -Drandomseed=false \
    -Dbacklight=false \
    -Drfkill=false \
    -Dxdg-autostart=false \
    -Dquotacheck=false \
    -Dsysupdate=false \
    -Dukify=false \
    -Dbootloader=false \
    -Danalyze=false \
    -Drepart=false \
    -Dkernel-install=false \
    -Dlibcryptsetup=false \
    -Dlibfido2=false \
    -Dtpm2=false \
    -Dgnutls=false \
    -Ddefault-dnssec=false \
    --default-library=shared
  ninja -C build libsystemd.so
}

install() {
  cd "${srcdir}/systemd-${version}"
  install -Dm755 build/src/libsystemd/libsystemd.so "${pkgdir}/usr/lib/libsystemd.so"
  install -Dm755 build/src/libsystemd/libsystemd.so.0 "${pkgdir}/usr/lib/libsystemd.so.0"
  install -Dm644 src/systemd/sd-id128.h "${pkgdir}/usr/include/systemd/sd-id128.h"
  install -Dm644 src/systemd/sd-daemon.h "${pkgdir}/usr/include/systemd/sd-daemon.h"
  install -Dm644 src/systemd/sd-journal.h "${pkgdir}/usr/include/systemd/sd-journal.h"
}
