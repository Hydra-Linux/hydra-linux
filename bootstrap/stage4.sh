#!/bin/bash -e
# Stage 4: Build flash package manager and bootstrap full system
source "$(dirname "$0")/build.env"

echo -e "${YELLOW}[Hydra] Stage 4: Building flash package manager${RESET}"

if [ "$EUID" -ne 0 ]; then echo "Please run as root"; exit 1; fi

cd /home/oliwier/hydra-linux/flash
make clean 2>/dev/null || true
make -j$JOBS

mkdir -p /usr/bin /etc/flash /var/lib/flash /var/cache/flash
cp flash /usr/bin/flash

cat > /etc/flash/flash.conf << 'EOF'
[paths]
root = "/"
db = "/var/lib/flash/flash.db"
cache = "/var/cache/flash"
build_dir = "/var/cache/flash/build"
recipes_dir = "/var/lib/flash/recipes"

[build]
sandbox = true
sandbox_cmd = "/usr/bin/bwrap"
jobs = 4
network = false
source_threshold = 104857600
binary_threshold = 471859200

[gpg]
keyring = "/etc/flash/trusted-keys"
sign = true

[install]
backup = true
backup_dir = "/var/backups/flash"

[repos]
default = "https://repo.hydra-linux.org/stable"
EOF

echo "Initializing flash database..."
flash config init 2>/dev/null || true

echo -e "${YELLOW}Building packages with flash...${RESET}"

cd /home/oliwier/hydra-linux/recipes

for recipe in base/*/recipe.sh; do
  pkg=$(basename $(dirname $recipe))
  echo "Building $pkg..."
  flash make "$(dirname $recipe)"
  flash install "$pkg"
done

echo "Installing GRUB..."
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=Hydra
grub-mkconfig -o /boot/grub/grub.cfg

echo "Setting root password..."
echo "root:hydra" | chpasswd || echo "Set root password manually later"

echo -e "${GREEN}Stage 4 complete. Hydra Linux is ready!${RESET}"
touch /tmp/.hydra-stage4-done
