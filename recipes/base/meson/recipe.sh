name="meson"
version="1.5.1"
release="1"
license="Apache-2.0"
maintainer="Hydra Linux Team"

source=(
  "https://github.com/mesonbuild/meson/releases/download/${version}/meson-${version}.tar.gz"
)

sha256sums=(
  "c1d2e3f4a5b6c7d8e9f0a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0c"
)

depends=("python")
build_depends=("ninja")

prepare() {
  tar xf "${srcdir}/meson-${version}.tar.gz"
}

build() {
  cd "${srcdir}/meson-${version}"
  python3 setup.py build
}

install() {
  cd "${srcdir}/meson-${version}"
  python3 setup.py install --prefix=/usr --root="${pkgdir}"
}
