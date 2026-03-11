#!/usr/bin/env bash
set -euo pipefail

# ── gsd-migrate installer ───────────────────────────────────────────────────
# Adds /gsd migrate to an existing GSD-2 installation.
# Patches the runtime extension directory (~/.gsd/agent/extensions/gsd/).
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/jonathancostin/gsd-migrate/main/install.sh | bash
#
# To uninstall:
#   curl -fsSL https://raw.githubusercontent.com/jonathancostin/gsd-migrate/main/install.sh | bash -s -- --uninstall
# ─────────────────────────────────────────────────────────────────────────────

REPO="jonathancostin/gsd-migrate"
BRANCH="main"
BASE_URL="https://raw.githubusercontent.com/${REPO}/${BRANCH}"
EXT_DIR="${HOME}/.gsd/agent/extensions/gsd"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

info()  { echo -e "${CYAN}▸${RESET} $1"; }
ok()    { echo -e "${GREEN}✓${RESET} $1"; }
warn()  { echo -e "${YELLOW}⚠${RESET} $1"; }
fail()  { echo -e "${RED}✗${RESET} $1"; exit 1; }

# ── Uninstall ────────────────────────────────────────────────────────────────

if [[ "${1:-}" == "--uninstall" ]]; then
  echo -e "\n${BOLD}gsd-migrate uninstaller${RESET}\n"

  if [[ -d "${EXT_DIR}/migrate" ]]; then
    rm -rf "${EXT_DIR}/migrate"
    ok "Removed migrate/"
  fi

  if [[ -f "${EXT_DIR}/prompts/review-migration.md" ]]; then
    rm -f "${EXT_DIR}/prompts/review-migration.md"
    ok "Removed prompts/review-migration.md"
  fi

  # Restore original commands.ts and files.ts from backup
  for f in commands.ts files.ts; do
    if [[ -f "${EXT_DIR}/${f}.pre-migrate-backup" ]]; then
      mv "${EXT_DIR}/${f}.pre-migrate-backup" "${EXT_DIR}/${f}"
      ok "Restored original ${f}"
    fi
  done

  echo -e "\n${GREEN}${BOLD}Uninstalled.${RESET} Restart gsd to pick up changes.\n"
  exit 0
fi

# ── Install ──────────────────────────────────────────────────────────────────

echo -e "\n${BOLD}gsd-migrate installer${RESET}"
echo -e "Adds ${CYAN}/gsd migrate${RESET} to your GSD-2 installation.\n"

# Preflight
[[ -d "${EXT_DIR}" ]] || fail "GSD extension directory not found at ${EXT_DIR}\nIs GSD-2 installed? Run gsd once first."

# Files to download
MIGRATE_FILES=(
  "ext/migrate/command.ts"
  "ext/migrate/index.ts"
  "ext/migrate/parser.ts"
  "ext/migrate/parsers.ts"
  "ext/migrate/preview.ts"
  "ext/migrate/transformer.ts"
  "ext/migrate/types.ts"
  "ext/migrate/validator.ts"
  "ext/migrate/writer.ts"
)

PATCHED_FILES=(
  "ext/commands.ts"
  "ext/files.ts"
)

PROMPT_FILES=(
  "ext/prompts/review-migration.md"
)

# Create directories
mkdir -p "${EXT_DIR}/migrate"
mkdir -p "${EXT_DIR}/prompts"

# Download migrate module
info "Downloading migrate module..."
for f in "${MIGRATE_FILES[@]}"; do
  target="${EXT_DIR}/migrate/$(basename "$f")"
  curl -fsSL "${BASE_URL}/${f}" -o "${target}" || fail "Failed to download ${f}"
done
ok "migrate/ (9 files)"

# Download prompt template
info "Downloading review prompt..."
for f in "${PROMPT_FILES[@]}"; do
  target="${EXT_DIR}/prompts/$(basename "$f")"
  curl -fsSL "${BASE_URL}/${f}" -o "${target}" || fail "Failed to download ${f}"
done
ok "prompts/review-migration.md"

# Back up and replace host files
info "Patching commands.ts and files.ts..."
for f in "${PATCHED_FILES[@]}"; do
  base="$(basename "$f")"
  target="${EXT_DIR}/${base}"
  if [[ -f "${target}" && ! -f "${target}.pre-migrate-backup" ]]; then
    cp "${target}" "${target}.pre-migrate-backup"
  fi
  curl -fsSL "${BASE_URL}/${f}" -o "${target}" || fail "Failed to download ${f}"
done
ok "commands.ts (migrate command wired in)"
ok "files.ts (wider requirement ID regex)"

# Done
echo -e "\n${GREEN}${BOLD}Installed!${RESET}"
echo -e ""
echo -e "  Restart gsd, then run:  ${CYAN}/gsd migrate${RESET}  or  ${CYAN}/gsd migrate ~/path/to/project${RESET}"
echo -e ""
echo -e "  To uninstall later:"
echo -e "  ${YELLOW}curl -fsSL https://raw.githubusercontent.com/${REPO}/${BRANCH}/install.sh | bash -s -- --uninstall${RESET}"
echo -e ""
warn "This patch will be overwritten when gsd-pi updates. Re-run the installer after updating."
echo ""
