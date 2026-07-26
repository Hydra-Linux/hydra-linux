name="hyprland"
version="0.43.0"
release="1"
license="BSD-3-Clause"
maintainer="Hydra Linux Team"

source=(
  "https://github.com/hyprwm/Hyprland/releases/download/v${version}/Hyprland-v${version}.tar.gz"
)

sha256sums=(
  "0000000000000000000000000000000000000000000000000000000000000000"
)

depends=("glibc" "libx11" "libxcb" "wayland" "libdrm" "pixman" "libinput" "libxkbcommon" "cairo" "pango" "mesa" "libglvnd" "udis86" "xcb-util-wm")
build_depends=("cmake" "ninja" "meson" "pkgconf")

build() {
  cd "${srcdir}/Hyprland-v${version}"
  cmake -B build -G Ninja -DCMAKE_INSTALL_PREFIX=/usr
  ninja -C build
}

install() {
  cd "${srcdir}/Hyprland-v${version}"
  DESTDIR="${pkgdir}" cmake --install build
}
