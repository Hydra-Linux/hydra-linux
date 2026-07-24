#!/bin/bash -e
# Hydra Linux - Full Bootstrap Orchestrator
set -e

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; RESET='\033[0m'

echo -e "${GREEN}"
echo "╔══════════════════════════════════════╗"
echo "║        Hydra Linux Bootstrap         ║"
echo "║     Many heads. One system.          ║"
echo "╚══════════════════════════════════════╝"
echo -e "${RESET}"

if [ "$EUID" -ne 0 ]; then
  echo -e "${RED}Please run as root.${RESET}"
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
LOG="/var/log/hydra-bootstrap.log"

run_stage() {
  local stage=$1 label=$2 marker="/tmp/.hydra-stage${stage}-done"
  if [ -f "$marker" ]; then
    echo -e "${YELLOW}[$label] already complete. Skipping.${RESET}"
    return 0
  fi
  echo -e "${YELLOW}[$label] Starting...${RESET}"
  if "$SCRIPT_DIR/stage${stage}.sh" 2>&1 | tee -a "$LOG"; then
    echo -e "${GREEN}[$label] Done.${RESET}"
    touch "$marker"
  else
    echo -e "${RED}[$label] FAILED. Check $LOG${RESET}"
    exit 1
  fi
}

> "$LOG"
echo "Hydra Linux bootstrap started at $(date)" >> "$LOG"

run_stage 0 "Cross-toolchain"
run_stage 1 "Minimal toolchain"
run_stage 2 "Final toolchain"
run_stage 3 "Base system"
run_stage 4 "Package manager + full build"

echo -e "${GREEN}"
echo "╔══════════════════════════════════════╗"
echo "║   Hydra Linux bootstrap complete!    ║"
echo "║   Reboot into your new system.       ║"
echo "╚══════════════════════════════════════╝"
echo -e "${RESET}"
