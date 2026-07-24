# Contributing to Hydra Linux

## Code of Conduct

We are committed to providing a welcoming and inclusive environment. All participants are expected to:

- Be respectful and considerate
- Accept constructive criticism gracefully
- Focus on what is best for the community
- Show empathy towards other community members

Unacceptable behavior will not be tolerated.

## How to Report Bugs

1. **Search** existing [issues](https://github.com/yourorg/hydra-linux/issues) first
2. If not found, open a **new issue** with:
   - A clear, descriptive title
   - Steps to reproduce
   - Expected vs actual behavior
   - System information (run `flash info` or attach `/var/log/flash.log`)
   - Screenshots if applicable

## Package Contribution Process

1. Read [docs/package-creation.md](package-creation.md) for recipe format
2. Test your recipe locally with `flash build <package>`
3. Fork the repository and create a feature branch
4. Submit a pull request with:
   - One package per PR (unless tightly related)
   - A meaningful commit message (`recipes/category: add package-name`)
   - Reference any related issues

## Code Style for Recipes

- Use 2-space indentation
- Variables in double quotes
- Prefer `"$pkgdir/usr"` over `"$pkgdir"/usr`
- Keep `build()` and `install()` functions focused
- Order metadata: `name`, `version`, `release`, `source`, `sha256sums`, `depends`, `makedepends`
- Use `[[ ]]` for conditional tests (Bash 4.0+)

### Recipe Template

```bash
name="package"
version="1.0.0"
release=1
source=("https://example.org/\$name-\$version.tar.gz")
sha256sums=("0000000000000000000000000000000000000000000000000000000000000000")
depends=()
makedepends=()

build() {
  ./configure --prefix=/usr
  make
}

install() {
  make DESTDIR="$pkgdir" install
}
```

## Pull Request Workflow

1. Push to your fork and open a PR against `main`
2. GitHub Actions will run:
   - `build-flash` — Compile the package manager
   - `lint-recipes` — Syntax-check all recipes
   - `build-website` — Validate website HTML
3. Address any CI failures
4. Request a review from a maintainer
5. Once approved, a maintainer will merge

## Community Channels

- **GitHub Issues** — Bug reports and feature requests
- **Matrix** — `#hydra-linux:matrix.org`
- **IRC** — `#hydra-linux` on Libera.Chat
- **Forum** — https://discourse.hydra-linux.org

## Development Setup

```bash
git clone https://github.com/yourorg/hydra-linux
cd hydra-linux

# Build the flash package manager
make flash

# Run bootstrap (if building from source)
sudo make bootstrap
```
