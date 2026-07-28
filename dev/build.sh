#!/bin/bash -e
# Hydra Linux - Development Build Script
# Usage: ./dev/build.sh [target]

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$PROJECT_DIR"

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; RESET='\033[0m'

echo -e "${GREEN}=== Hydra Linux Build System ===${RESET}"

build_flash() {
    echo -e "${YELLOW}Building flash package manager...${RESET}"
    make -C flash clean 2>/dev/null || true
    make -C flash
    echo -e "${GREEN}flash built: flash/flash${RESET}"
}

test_flash() {
    echo -e "${YELLOW}Testing flash...${RESET}"
    ./flash/flash --help > /dev/null 2>&1 && echo -e "${GREEN}flash OK${RESET}" || echo -e "${RED}flash FAILED${RESET}"
}

lint_recipes() {
    echo -e "${YELLOW}Checking recipe syntax...${RESET}"
    local errors=0
    for f in recipes/*/*/recipe.sh; do
        if bash -n "$f" 2>/dev/null; then
            echo -e "  ${GREEN}OK${RESET} $f"
        else
            echo -e "  ${RED}FAIL${RESET} $f"
            errors=$((errors + 1))
        fi
    done
    [ "$errors" -eq 0 ] && echo -e "${GREEN}All recipes OK${RESET}" || echo -e "${RED}$errors recipe(s) failed${RESET}"
    return "$errors"
}

case "${1:-all}" in
    flash)
        build_flash
        test_flash
        ;;
    lint)
        lint_recipes
        ;;
    all)
        build_flash
        test_flash
        lint_recipes
        ;;
    *)
        echo "Usage: $0 [flash|lint|all]"
        exit 1
        ;;
esac
