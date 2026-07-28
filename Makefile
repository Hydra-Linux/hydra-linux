SHELL := /bin/bash
ROOT_DIR := $(patsubst %/,%,$(dir $(abspath $(lastword $(MAKEFILE_LIST)))))
include $(ROOT_DIR)/config.mk

.PHONY: all flash test lint clean help

all: flash lint

help:
	@echo "Hydra Linux Build System"
	@echo "======================="
	@echo "Targets:"
	@echo "  all         - Build flash + lint (default)"
	@echo "  flash       - Build flash package manager"
	@echo "  test        - Run flash test suite"
	@echo "  lint        - Check recipe syntax"
	@echo "  clean       - Clean build artifacts"
	@echo ""
	@echo "Legacy (cross-compilation):"
	@echo "  toolchain   - Build cross-compilation toolchain (stage 0-2)"
	@echo "  base        - Build base system (stage 3)"
	@echo "  bootstrap   - Run full bootstrap pipeline"
	@echo ""
	@echo "See bootstrap/build-all.sh for the legacy pipeline."

flash:
	@$(MAKE) -C flash

test: flash
	cd tests && bash test_flash.sh

lint:
	@errors=0; \
	for f in recipes/*/*/recipe.sh; do \
		if bash -n "$$f" 2>/dev/null; then \
			echo "  OK: $$f"; \
		else \
			echo "  FAIL: $$f"; \
			errors=$$((errors + 1)); \
		fi; \
	done; \
	[ "$$errors" -eq 0 ] && echo "All recipes OK" || (echo "$$errors recipe(s) failed"; exit 1)

clean:
	rm -rf $(ROOT_DIR)/build/out
	$(MAKE) -C flash clean
