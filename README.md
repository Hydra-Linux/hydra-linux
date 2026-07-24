# Hydra Linux

![CI](https://github.com/yourorg/hydra-linux/actions/workflows/build.yml/badge.svg)
![License](https://img.shields.io/badge/license-GPL--3.0-blue.svg)

**Many heads. One system.**

Hydra Linux is a source-based, rolling-release Linux distribution for x86_64. It combines the flexibility of source-based package management with optional binary caching for practical daily use.

## Features

- **flash package manager** — hybrid source/binary package manager with sandboxed builds
- **3-tier build system** — packages are built from source (tier 1), distributed as binaries (tier 2), or pre-compiled (tier 3)
- **KDE Plasma** default desktop with choice of GNOME, Xfce, Sway, or no desktop
- **Rolling releases** via ISO snapshots built from current recipe tree

## Quick Start

```bash
git clone https://github.com/yourorg/hydra-linux
cd hydra-linux
sudo ./bootstrap/build-all.sh
```

## Package Manager

flash is the native package manager. Basic usage:

| Command                    | Description                  |
|----------------------------|------------------------------|
| `flash install <pkg>`      | Install a package            |
| `flash remove <pkg>`       | Remove a package             |
| `flash build <pkg>`        | Build from source            |
| `flash search <term>`      | Search available packages    |
| `flash update`             | Sync recipe tree             |
| `flash list`               | List installed packages      |
| `flash info <pkg>`         | Show package details         |

## Project Structure

```
hydra-linux/
├── bootstrap/          # Bootstrap scripts for building from source
├── flash/              # flash package manager source
├── recipes/            # Package recipes organized by category
│   ├── core/           # Base system packages
│   ├── desktop/        # Desktop environments & apps
│   └── extra/          # Additional software
├── iso/                # Live ISO builder
├── website/            # Project website
└── docs/               # Documentation
```

## Contributing

See [docs/contributing.md](docs/contributing.md) for guidelines. All contributions are welcome — package recipes, bug fixes, documentation, and infrastructure improvements.

## License

Hydra Linux is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
