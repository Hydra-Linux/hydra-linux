name="sudo"
version="1.9.15"
release="1"
license="ISC"
maintainer="Hydra Linux Team"

source=(
  "https://www.sudo.ws/dist/sudo-${version}.tar.gz"
)

sha256sums=(
  "c5d6e7f8a9b0c1d2e3f4a5b6c7d8e9f0a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5"
)

depends=("glibc" "zlib" "openssl")
build_depends=()

prepare() {
  tar xf "${srcdir}/sudo-${version}.tar.gz"
}

build() {
  cd "${srcdir}/sudo-${version}"
  ./configure --prefix=/usr \
    --with-rundir=/run/sudo \
    --with-vardir=/var/db/sudo \
    --with-logfac=auth \
    --with-env-editor \
    --with-passprompt="[sudo] password for %p: "
  make
}

install() {
  cd "${srcdir}/sudo-${version}"
  make DESTDIR="${pkgdir}" install
}

check() {
  cd "${srcdir}/sudo-${version}"
  make -j$(nproc) check
}
