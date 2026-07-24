.PHONY: all bootstrap flash recipes iso website clean

all: flash recipes

bootstrap:
	@echo "Running bootstrap scripts..."
	@sudo ./bootstrap/build-all.sh

flash:
	cd flash && make

recipes:
	@for f in recipes/*/*/recipe.sh; do \
		bash -n "$$f" && echo "OK: $$f" || echo "FAIL: $$f"; \
	done

iso:
	@echo "Building ISO..."
	@sudo ./iso/build-iso.sh

website:
	@echo "Website at website/index.html"

clean:
	cd flash && make clean 2>/dev/null || true
	@rm -rf /tmp/hydra-iso-build 2>/dev/null || true
	@echo "Clean complete."
