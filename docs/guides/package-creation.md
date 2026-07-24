# Package Creation Guide

## Recipe Format
Recipes are Bash scripts sourced by `flash`. Each recipe must define:

```bash
name="package-name"
version="1.0"
release=1
license=("MIT")
maintainer="Your Name <you@example.com>"
source=("https://example.com/$name-$version.tar.gz")
sha256sums=("abc123...")
depends=("glibc" "zlib")
build_depends=("cmake" "ninja")

build() {
    ./configure --prefix=/usr
    make -j$(nproc)
}

install() {
    make DESTDIR="$pkgdir" install
}
```

## Build Policy
- ≤ 100 MB source: compiled from source
- 100–450 MB: pre-built binary downloaded
- > 450 MB: pre-compiled parts assembled locally

## Multi-part packages
For packages > 450 MB, split into `.part.sh` files:

```bash
# recipe.sh (orchestrator)
name="large-pkg"
# declares parts:
# - large-pkg-core.part.sh
# - large-pkg-ui.part.sh
```

## Testing
Submit a PR to the `recipes` repository. CI will validate syntax and build.
