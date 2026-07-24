name="plasma"
version="6.1"
release="1"
license="GPL-2.0-only"
maintainer="Hydra Linux Team"

source=()
sha256sums=()
depends=("qt6" "wayland" "mesa" "glibc" "libx11" "libxcb" "libxkbcommon")
build_depends=("cmake" "extra-cmake-modules" "meson" "ninja" "gcc")

parts=(
  "plasma-desktop.part.sh"
  "plasma-workspace.part.sh"
  "kwin.part.sh"
  "sddm.part.sh"
)

prepare() {
  for part in "${parts[@]}"; do
    (
      source "${part}"
      prepare
    )
  done
}

build() {
  for part in "${parts[@]}"; do
    (
      source "${part}"
      build
    )
  done
}

install() {
  for part in "${parts[@]}"; do
    (
      source "${part}"
      install
    )
  done
}

check() {
  for part in "${parts[@]}"; do
    (
      source "${part}"
      check
    )
  done
}
