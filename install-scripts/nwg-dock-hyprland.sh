#!/usr/bin/env bash
# ==================================================
#  KoolDots (2026)
#  Project URL: https://github.com/LinuxBeginnings
#  License: GNU GPLv3
#  SPDX-License-Identifier: GPL-3.0-or-later
# ==================================================
# 💫 https://github.com/LinuxBeginnings 💫 #
# nwg-dock-hyprland (build from source) #

# specific branch or release (fallback)
tag_default="auto"
if [ -z "${NWG_DOCK_HYPRLAND_TAG:-}" ]; then
  TAGS_FILE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/hypr-tags.env"
  [ -f "$TAGS_FILE" ] && source "$TAGS_FILE"
fi
TAG_SRC="${NWG_DOCK_HYPRLAND_TAG:-$tag_default}"
[[ "$TAG_SRC" =~ ^(auto|latest)$ ]] && git_ref="" || git_ref="$TAG_SRC"

DO_INSTALL=1
[ "$1" = "--dry-run" ] || [ "${DRY_RUN}" = "1" ] || [ "${DRY_RUN}" = "true" ] && { DO_INSTALL=0; echo "${NOTE} DRY RUN: install step will be skipped."; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PARENT_DIR="$SCRIPT_DIR/.."
cd "$PARENT_DIR" || exit 1
source "$(dirname "$(readlink -f "$0")")/Global_functions.sh"

LOG="$PARENT_DIR/Install-Logs/install-$(date +%d-%H%M%S)_nwg_dock_hyprland.log"
MLOG="$PARENT_DIR/Install-Logs/install-$(date +%d-%H%M%S)_nwg_dock_hyprland2.log"
USER_LOCAL_DATA_DIR="$HOME/.local/share/nwg-dock-hyprland"
USER_LOCAL_CONFIG_DIR="$HOME/.config/nwg-dock-hyprland"

# Build-time dependencies for nwg-dock-hyprland (Fedora)
DEPS=(
  golang
  gtk3-devel
  gtk-layer-shell-devel
  gobject-introspection-devel
  gcc
  pkgconf
  git
)

printf "\n%s - Installing ${YELLOW}nwg-dock-hyprland dependencies${RESET} .... \n" "${INFO}"
for PKG in "${DEPS[@]}"; do
  install_package "$PKG" "$LOG"
done

# Ensure Go toolchain is available in PATH
if command -v go >/dev/null 2>&1; then
  GO_BIN="$(command -v go)"
elif [ -x "/usr/lib/go/bin/go" ]; then
  GO_BIN="/usr/lib/go/bin/go"
  export PATH="$(dirname "$GO_BIN"):$PATH"
elif [ -x "/usr/local/go/bin/go" ]; then
  GO_BIN="/usr/local/go/bin/go"
  export PATH="$(dirname "$GO_BIN"):$PATH"
else
  echo -e "${ERROR} Go compiler not found after dependency installation." | tee -a "$LOG"
  exit 1
fi

GO_VERSION="$("$GO_BIN" version 2>/dev/null || echo "unknown")"
echo "${INFO} Using Go compiler: ${YELLOW}${GO_VERSION}${RESET}" | tee -a "$LOG"

# Set up pkg-config search paths
export PATH="/usr/local/bin:${PATH}"
if [[ ":${PKG_CONFIG_PATH:-}:" != *":/usr/local/share/pkgconfig:"* ]]; then
  export PKG_CONFIG_PATH="/usr/local/share/pkgconfig:${PKG_CONFIG_PATH:-}"
fi
if [[ ":${PKG_CONFIG_PATH}:" != *":/usr/local/lib/pkgconfig:"* ]]; then
  export PKG_CONFIG_PATH="/usr/local/lib/pkgconfig:${PKG_CONFIG_PATH}"
fi

SRC_DIR="$PARENT_DIR/nwg-dock-hyprland-src"
rm -rf "$SRC_DIR" 2>/dev/null || true
printf "${INFO} Installing ${YELLOW}nwg-dock-hyprland ${git_ref:-default-branch}${RESET} ...\n"

if git clone --recursive ${git_ref:+-b "$git_ref"} https://github.com/nwg-piotr/nwg-dock-hyprland.git "$SRC_DIR"; then
    cd "$SRC_DIR" || exit 1
    mkdir -p bin

    export CGO_ENABLED=1

    echo "${INFO} Downloading Go module dependencies..." | tee -a "$LOG"
    "$GO_BIN" mod download 2>&1 | tee -a "$MLOG"

    echo "${INFO} Building nwg-dock-hyprland..." | tee -a "$LOG"
    BUILD_SUCCESS=0
    rm -f nwg-dock-hyprland bin/nwg-dock-hyprland 2>/dev/null || true

    if "$GO_BIN" build -v -o bin/nwg-dock-hyprland . 2>&1 | tee -a "$MLOG"; then
        [ -f bin/nwg-dock-hyprland ] && [ -x bin/nwg-dock-hyprland ] && BUILD_SUCCESS=1
    elif [ -f Makefile ] && grep -q '^build:' Makefile; then
        if make -B build 2>&1 | tee -a "$MLOG"; then
            if [ -f bin/nwg-dock-hyprland ] && [ -x bin/nwg-dock-hyprland ]; then
                BUILD_SUCCESS=1
            elif [ -f nwg-dock-hyprland ] && [ -x nwg-dock-hyprland ]; then
                BUILD_SUCCESS=1
            fi
        fi
    fi

    BIN_SRC=""
    if [ -f bin/nwg-dock-hyprland ] && [ -x bin/nwg-dock-hyprland ]; then
        BIN_SRC="bin/nwg-dock-hyprland"
    elif [ -f nwg-dock-hyprland ] && [ -x nwg-dock-hyprland ]; then
        BIN_SRC="nwg-dock-hyprland"
    fi

    if [ "$BUILD_SUCCESS" -eq 1 ] && [ -n "$BIN_SRC" ]; then
        if [ $DO_INSTALL -eq 1 ]; then
            echo "${INFO} Installing nwg-dock-hyprland binary and data files..." | tee -a "$LOG"

            # Gracefully stop existing instance (exact binary match only to avoid terminating installer script)
            pkill -x nwg-dock-hyprland 2>/dev/null || true

            # Install binary to /usr/local/bin and /usr/bin
            sudo install -d -m 0755 /usr/local/bin
            sudo install -m 0755 "$BIN_SRC" /usr/local/bin/nwg-dock-hyprland
            sudo install -d -m 0755 /usr/bin
            sudo install -m 0755 "$BIN_SRC" /usr/bin/nwg-dock-hyprland 2>/dev/null || true

            # Ensure data assets (CSS and images) are installed to standard share paths
            sudo install -d -m 0755 /usr/local/share/nwg-dock-hyprland
            sudo install -d -m 0755 /usr/local/share/nwg-dock-hyprland/images
            sudo install -d -m 0755 /usr/share/nwg-dock-hyprland
            sudo install -d -m 0755 /usr/share/nwg-dock-hyprland/images

            if [ -f config/style.css ]; then
                sudo install -m 0644 config/style.css /usr/local/share/nwg-dock-hyprland/style.css
                sudo install -m 0644 config/style.css /usr/share/nwg-dock-hyprland/style.css
            elif [ -f style.css ]; then
                sudo install -m 0644 style.css /usr/local/share/nwg-dock-hyprland/style.css
                sudo install -m 0644 style.css /usr/share/nwg-dock-hyprland/style.css
            fi

            if [ -d images ]; then
                sudo cp -r images/* /usr/local/share/nwg-dock-hyprland/images/ 2>/dev/null || true
                sudo cp -r images/* /usr/share/nwg-dock-hyprland/images/ 2>/dev/null || true
            fi

            # Ensure user-local assets are present (runtime may read from ~/.local/share or ~/.config)
            mkdir -p "$USER_LOCAL_DATA_DIR/images"
            mkdir -p "$USER_LOCAL_CONFIG_DIR/wallust"

            if [ -f config/style.css ]; then
                cp -f config/style.css "$USER_LOCAL_DATA_DIR/style.css"
                if [ ! -s "$USER_LOCAL_CONFIG_DIR/style.css" ]; then
                    cp -f config/style.css "$USER_LOCAL_CONFIG_DIR/style.css"
                fi
            elif [ -f style.css ]; then
                cp -f style.css "$USER_LOCAL_DATA_DIR/style.css"
                if [ ! -s "$USER_LOCAL_CONFIG_DIR/style.css" ]; then
                    cp -f style.css "$USER_LOCAL_CONFIG_DIR/style.css"
                fi
            fi

            if [ -d images ]; then
                cp -f images/* "$USER_LOCAL_DATA_DIR/images/" 2>/dev/null || true
            fi

            # Clean up source dir
            cd "$PARENT_DIR" || true
            rm -rf "$SRC_DIR" 2>/dev/null || true

            if command -v nwg-dock-hyprland >/dev/null 2>&1 || [ -x /usr/local/bin/nwg-dock-hyprland ]; then
                printf "${OK} ${YELLOW}nwg-dock-hyprland${RESET} installed successfully from source.\n" 2>&1 | tee -a "$MLOG"
            else
                echo -e "${ERROR} Installation failed for ${YELLOW}nwg-dock-hyprland${RESET}" 2>&1 | tee -a "$MLOG"
            fi
        else
            echo "${NOTE} DRY RUN: skip install" | tee -a "$MLOG"
            cd "$PARENT_DIR" || true
        fi
    else
        echo -e "${ERROR} Compilation failed for ${YELLOW}nwg-dock-hyprland${RESET}" 2>&1 | tee -a "$LOG"
        cd "$PARENT_DIR" || true
        exit 1
    fi
else
    echo -e "${ERROR} Download failed for ${YELLOW}nwg-dock-hyprland${RESET}" 2>&1 | tee -a "$LOG"
    cd "$PARENT_DIR" || true
    exit 1
fi

printf "\n%.0s" {1..1}
