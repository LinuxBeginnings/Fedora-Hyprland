#!/usr/bin/env bash
# ==================================================
#  KoolDots (2026)
#  Project URL: https://github.com/LinuxBeginnings
#  License: GNU GPLv3
#  SPDX-License-Identifier: GPL-3.0-or-later
# ==================================================
# 💫 https://github.com/KoolDots 💫 #
# Final checking if packages are installed
# NOTE: These package checks are only the essentials

packages=(
    cliphist
    kvantum
    kvantum-qt5
    qt5-qtdeclarative
    qt5-qtquickcontrols2
    qt6-qtdeclarative
    rofi
    ImageMagick
    SwayNotificationCenter
    awww
    wallust
    waybar
    wl-clipboard
    wlogout
    kitty
    hypridle
    hyprlock
    hyprland
    nwg-dock-hyprland
    yazi
)

# Local packages that should be in /usr/local/bin/
local_pkgs_installed=(

)

## WARNING: DO NOT EDIT BEYOND THIS LINE IF YOU DON'T KNOW WHAT YOU ARE DOING! ##
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Change the working directory to the parent directory of the script
PARENT_DIR="$SCRIPT_DIR/.."
cd "$PARENT_DIR" || {
    echo "${ERROR} Failed to change directory to $PARENT_DIR"
    exit 1
}

# Source the global functions script
if ! source "$(dirname "$(readlink -f "$0")")/Global_functions.sh"; then
    echo "Failed to source Global_functions.sh"
    exit 1
fi

# Set the name of the log file to include the current date and time
LOG="Install-Logs/00_CHECK-$(date +%d-%H%M%S)_installed.log"
MIN_YAZI_VERSION="26.5.0"

version_ge() {
    [ "$(printf '%s\n' "$2" "$1" | sort -V | head -n1)" = "$2" ]
}

needs_yazi_install() {
    if rpm -q yazi &>/dev/null; then
        local current_version
        current_version="$(rpm -q --qf '%{VERSION}' yazi 2>/dev/null)"
        if [ -n "$current_version" ] && version_ge "$current_version" "$MIN_YAZI_VERSION"; then
            return 1
        fi
    fi
    return 0
}

printf "\n%s - Final Check if all ${SKY_BLUE}Essential packages${RESET} were installed \n" "${NOTE}"
# Initialize an empty array to hold missing packages
missing=()
local_missing=()
# Ensure yazi meets minimum version before final package check
if needs_yazi_install; then
    echo "${WARN} yazi is missing or below ${MIN_YAZI_VERSION}. Running install-scripts/yazi.sh." | tee -a "$LOG"
    bash "$SCRIPT_DIR/yazi.sh"
else
    echo "${OK} yazi meets minimum version requirement (>= ${MIN_YAZI_VERSION})." | tee -a "$LOG"
fi

# Function to check if a package is installed using rpm (Fedora)
is_installed_rpm() {
    rpm -q "$1" &>/dev/null
}

# Loop through each package
for pkg in "${packages[@]}"; do
    # Check if the package is installed via rpm
    if ! is_installed_rpm "$pkg"; then
        missing+=("$pkg")
    fi
done

# Check for local packages
for pkg1 in "${local_pkgs_installed[@]}"; do
    if ! [ -f "/usr/local/bin/$pkg1" ]; then
        local_missing+=("$pkg1")
    fi
done

# Log missing packages
if [ ${#missing[@]} -eq 0 ] && [ ${#local_missing[@]} -eq 0 ]; then
    echo "${OK} GREAT! It seems All ${YELLOW}essential packages${RESET} are installed." | tee -a "$LOG"
else
    if [ ${#missing[@]} -ne 0 ]; then
        echo "${WARN} The following packages are not installed and will be logged:"
        for pkg in "${missing[@]}"; do
            echo "$pkg"
            echo "$pkg" >>"$LOG" # Log the missing package to the file
        done
    fi

    if [ ${#local_missing[@]} -ne 0 ]; then
        echo "${WARN} The following local packages are missing from /usr/local/bin/ and will be logged:"
        for pkg1 in "${local_missing[@]}"; do
            echo "$pkg1 is not installed. can't find it in /usr/local/bin/"
            echo "$pkg1" >>"$LOG" # Log the missing local package to the file
        done
    fi

    # Add a timestamp when the missing packages were logged
    echo "${NOTE} Missing packages logged at $(date)" >>"$LOG"
fi
