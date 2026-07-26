SHELL := /bin/bash
ROOT_DIR := $(patsubst %/,%,$(dir $(abspath $(lastword $(MAKEFILE_LIST)))))
include $(ROOT_DIR)/config.mk

.PHONY: all clean distclean \
        toolchain kernel busybox openrc grub \
        rootfs iso hpm \
        help

all: toolchain kernel busybox openrc grub hpm rootfs iso

help:
	@echo "Hydra Linux Build System"
	@echo "======================="
	@echo "Targets:"
	@echo "  all         - Build everything"
	@echo "  toolchain   - Build cross-compilation toolchain"
	@echo "  kernel      - Build Linux kernel"
	@echo "  busybox     - Build BusyBox"
	@echo "  openrc      - Build OpenRC init system"
	@echo "  grub        - Build GRUB bootloader (EFI)"
	@echo "  hpm         - Build Hydra Package Manager"
	@echo "  rootfs      - Assemble root filesystem"
	@echo "  iso         - Generate EFI-bootable ISO"
	@echo "  clean       - Clean build artifacts"
	@echo "  distclean   - Full cleanup (incl. downloads)"

# ---------------------------------------------------------------------------
# Toolchain
# ---------------------------------------------------------------------------
toolchain:
	@$(MAKE) -f $(BUILD_DIR)/toolchain.mk

# ---------------------------------------------------------------------------
# Components
# ---------------------------------------------------------------------------
kernel:
	@$(MAKE) -f $(BUILD_DIR)/kernel.mk

busybox:
	@$(MAKE) -f $(BUILD_DIR)/busybox.mk

openrc:
	@$(MAKE) -f $(BUILD_DIR)/openrc.mk

grub:
	@$(MAKE) -f $(BUILD_DIR)/grub.mk

hpm:
	@$(MAKE) -f $(BUILD_DIR)/hpm.mk

# ---------------------------------------------------------------------------
# Rootfs assembly
# ---------------------------------------------------------------------------
rootfs: kernel busybox openrc hpm
	@$(MAKE) -f $(BUILD_DIR)/rootfs.mk

# ---------------------------------------------------------------------------
# ISO generation
# ---------------------------------------------------------------------------
iso: rootfs
	@$(MAKE) -f $(BUILD_DIR)/iso.mk

# ---------------------------------------------------------------------------
# Cleanup
# ---------------------------------------------------------------------------
clean:
	rm -rf $(OUTPUT_DIR)/*
	rm -rf $(HPM_DIR)/*.egg-info $(HPM_DIR)/build $(HPM_DIR)/dist

distclean: clean
	rm -rf $(SOURCES_DIR)/*
	rm -rf $(BUILD_DIR)/*.stamp
