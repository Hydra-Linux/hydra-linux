# Package Creation Guide

## Recipe Format

A flash recipe is a Bash script with `build()`, `install()`, and optionally `check()` functions. Recipes live under `recipes/<category>/<package>/recipe.sh`.

### Minimal Example: `recipes/core/hello/recipe.sh`

```bash
name="hello"
version="2.12.1"
release=1
source=("https://ftp.gnu.org/gnu/\$name/\$name-\$version.tar.gz")
sha256sums=("...")

build() {
  ./configure --prefix=/usr
  make
}

check() {
  make check
}

install() {
  make DESTDIR="$pkgdir" install
}
```

## Recipe Components

### Metadata Variables

| Variable       | Required | Description                      |
|----------------|----------|----------------------------------|
| `name`         | Yes      | Package name (lowercase, no spaces) |
| `version`      | Yes      | Upstream version string          |
| `release`      | Yes      | Hydra package release number     |
| `source`       | Yes      | Array of source URLs             |
| `sha256sums`   | Yes      | Array of SHA-256 checksums       |
| `depends`      | No       | Array of runtime dependencies    |
| `makedepends`  | No       | Array of build-time dependencies |
| `arch`         | No       | Target architectures (default: x86_64) |

### Functions

- **`build()`** — Configure and compile the source
- **`check()`** — Run test suite (optional, runs after build if present)
- **`install()`** — Install files into `$pkgdir`

### Available Variables Inside Functions

| Variable  | Description                              |
|-----------|------------------------------------------|
| `$srcdir` | Directory where sources are extracted    |
| `$pkgdir` | Package staging directory (`/` relative) |

## Dependency Declarations

### Runtime Dependencies

```bash
depends=(
  "glibc>=2.35"
  "libfoo"
  "libbar>=1.2"
)
```

### Build Dependencies

```bash
makedepends=(
  "cmake"
  "ninja"
  "python-sphinx"
)
```

## Multi-Part Packages (Tier 3)

Split a single source into multiple packages:

```bash
# File: recipes/extra/libfoo/recipe.sh

packages=(libfoo libfoo-dev libfoo-docs)

build() { ... }

package_libfoo() {
  make DESTDIR="$pkgdir" install
  rm -rf "$pkgdir/usr/include" "$pkgdir/usr/share/doc"
}

package_libfoo-dev() {
  make DESTDIR="$pkgdir" install
  rm -rf "$pkgdir/usr/lib" "$pkgdir/usr/share/doc"
}

package_libfoo-docs() {
  make DESTDIR="$pkgdir" install
  rm -rf "$pkgdir/usr/lib" "$pkgdir/usr/include"
}
```

## Testing Locally

```bash
# Build a recipe
flash build hello

# Install the built package
flash install hello

# Check the build log
cat /var/cache/flash/build/hello/build.log
```

## Submitting to Repository

1. Fork the [hydra-linux recipes repo](https://github.com/yourorg/hydra-linux)
2. Create a branch: `git checkout -b add-hello`
3. Add the recipe: `recipes/core/hello/recipe.sh`
4. Commit: `git add recipes/core/hello && git commit -m "recipes/core: add hello"`
5. Push and open a pull request
6. Ensure all CI checks pass

## Best Practices

- Verify SHA-256 checksums with `sha256sum`
- Use `$pkgdir` not hardcoded paths
- Run `flash build` locally before submitting
- Follow existing recipes for style consistency
- Add `check()` when the upstream test suite is reasonable
