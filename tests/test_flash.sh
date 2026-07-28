#!/bin/bash -e
# Flash package manager test suite
TEST_DIR="$(mktemp -d)"
FLASH_BIN="../flash/flash"
FLASH_CONF="${TEST_DIR}/flash.conf"
CACHE_DIR="${TEST_DIR}/cache"
BUILD_DIR="${TEST_DIR}/build"
RECIPES_DIR="${TEST_DIR}/recipes"
DB_PATH="${TEST_DIR}/flash.db"
PASS=0
FAIL=0

cleanup() { rm -rf "$TEST_DIR"; }
trap cleanup EXIT

mkdir -p "$CACHE_DIR" "$BUILD_DIR" "$RECIPES_DIR/test-pkg"

cat > "$FLASH_CONF" << CONF
root = 
db = $DB_PATH
cache_dir = $CACHE_DIR
build_dir = $BUILD_DIR
recipes_dir = $RECIPES_DIR
sandbox = 0
jobs = 1
repo_url = https://repo.hydralinux.org/flash
CONF

flash() {
  "$FLASH_BIN" --config "$FLASH_CONF" "$@"
}

ok() {
  echo "  PASS: $1"
  PASS=$((PASS + 1))
}

fail() {
  echo "  FAIL: $1"
  FAIL=$((FAIL + 1))
}

check() {
  if eval "$2"; then ok "$1"; else fail "$1"; fi
}

RES=0

echo "=== Flash Test Suite ==="
echo ""

# --- Test 1: Version ---
echo "[Test 1: version]"
output=$(flash --version 2>&1)
check "shows version" "echo '$output' | grep -q 'flash'"

# --- Test 2: Help ---
echo "[Test 2: help]"
output=$(flash --help 2>&1)
check "shows usage" "echo '$output' | grep -qi 'usage'"

# --- Test 3: Config display ---
echo "[Test 3: flash config]"
output=$(flash config 2>&1)
check "config shows db" "echo '$output' | grep -q 'db_path'"
check "config shows cache" "echo '$output' | grep -q 'cache_dir'"

# --- Test 4: Make a simple package ---
echo "[Test 4: flash make]"
cat > "$RECIPES_DIR/test-pkg/recipe.sh" << 'RECIPE'
name="test-pkg"
version="1.0"
release=1
license="MIT"
maintainer="Test"

depends=()
build_depends=()

prepare() {
  mkdir -p "${srcdir}"
}

build() {
  echo "building" > "${srcdir}/hello.txt"
}

install() {
  mkdir -p "${pkgdir}/usr/share"
  cp "${srcdir}/hello.txt" "${pkgdir}/usr/share/"
}
RECIPE

flash make "$RECIPES_DIR/test-pkg" 2>&1
check "make succeeds" "[ -f '${CACHE_DIR}/test-pkg-1.0.tar.zst' ]"
check "files manifest exists" "[ -f '${CACHE_DIR}/test-pkg-1.0.files' ]"
check "files manifest non-empty" "[ -s '${CACHE_DIR}/test-pkg-1.0.files' ]"

# --- Test 5: Check DB after make ---
echo "[Test 5: DB operations]"
check "db has package" "flash list 2>&1 | grep -q 'test-pkg'"

# --- Test 6: Info command ---
echo "[Test 6: flash info]"
output=$(flash info test-pkg 2>&1)
check "info shows name" "echo '$output' | grep -q 'test-pkg'"
check "info shows version" "echo '$output' | grep -q '1.0'"

# --- Test 7: Contents command ---
echo "[Test 7: flash contents]"
output=$(flash contents test-pkg 2>&1)
check "contents shows files" "echo '$output' | grep -q '/usr/share/'"

# --- Test 8: Find command ---
echo "[Test 8: flash find]"
output=$(flash find test 2>&1)
check "find works" "echo '$output' | grep -q 'test-pkg'"

# --- Test 9: JSON output ---
echo "[Test 9: JSON output]"
output=$(flash --json info test-pkg 2>&1)
check "json info" "echo '$output' | grep -q '\"name\":\"test-pkg\"'"

# --- Test 10: Cache command ---
echo "[Test 10: flash cache]"
output=$(flash cache 2>&1)
check "cache shows size" "echo '$output' | grep -q 'Cache:'"

# --- Test 11: Cache clean dry-run ---
echo "[Test 11: flash cache clean --dry-run]"
output=$(flash --dry-run cache clean 2>&1)
check "dry-run clean" "echo '$output' | grep -q 'Would clean'"

# --- Test 12: Find owner ---
echo "[Test 12: flash find-owner]"
output=$(flash find-owner /usr/share/hello.txt 2>&1)
check "finds owner" "echo '$output' | grep -q 'test-pkg'"

# --- Test 13: Freeze/Unfreeze ---
echo "[Test 13: flash freeze/unfreeze]"
flash freeze test-pkg 2>&1
check "freeze succeeds" "echo 'y' | flash remove test-pkg 2>&1 | grep -q 'held'"
flash unfreeze test-pkg 2>&1

# --- Test 14: Audit ---
echo "[Test 14: flash audit]"
output=$(flash audit 2>&1)
check "audit succeeds" "echo '$output' | grep -q 'audit'"

# --- Test 15: Remove ---
echo "[Test 15: flash remove --dry-run]"
output=$(flash --dry-run remove test-pkg 2>&1)
check "dry-run remove" "echo '$output' | grep -q 'Would remove'"

# --- Test 16: Make with directory path ---
echo "[Test 16: flash make with directory path]"
mkdir -p "$RECIPES_DIR/test2"
cat > "$RECIPES_DIR/test2/recipe.sh" << 'RECIPE2'
name="test2"
version="2.0"
release=1
license="MIT"
maintainer="Test"
depends=()
build_depends=()
prepare() { mkdir -p "${srcdir}"; }
build() { echo "pkg2" > "${srcdir}/file2.txt"; }
install() { mkdir -p "${pkgdir}/opt" && cp "${srcdir}/file2.txt" "${pkgdir}/opt/"; }
RECIPE2
flash make "$RECIPES_DIR/test2" 2>&1
check "directory path make works" "[ -f '${CACHE_DIR}/test2-2.0.tar.zst' ]"
flash find-owner /opt/file2.txt 2>&1
check "find-owner test2" "flash find-owner /opt/file2.txt 2>&1 | grep -q 'test2'"

# --- Test 17: Config from nonexistent path uses defaults ---
echo "[Test 17: Default config fallback]"
mkdir -p /tmp/fake-flash
output=$(flash --config /nonexistent/conf config 2>&1)
check "defaults work" "echo '$output' | grep -q 'cache_dir'"

echo ""
echo "=== Results: $PASS passed, $FAIL failed ==="
[ "$FAIL" -eq 0 ]
