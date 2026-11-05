#!/bin/bash
# ==================================================
#  KoolDots (2026)
#  Project URL: https://github.com/LinuxBeginnings
#  License: GNU GPLv3
#  SPDX-License-Identifier: GPL-3.0-or-later
# ==================================================
# https://github.com/KoolDots

# Set some colors for output messages
OK="$(tput setaf 2)[OK]$(tput sgr0)"
ERROR="$(tput setaf 1)[ERROR]$(tput sgr0)"
NOTE="$(tput setaf 3)[NOTE]$(tput sgr0)"
INFO="$(tput setaf 4)[INFO]$(tput sgr0)"
WARN="$(tput setaf 1)[WARN]$(tput sgr0)"
CAT="$(tput setaf 6)[ACTION]$(tput sgr0)"
MAGENTA="$(tput setaf 5)"
ORANGE="$(tput setaf 214)"
WARNING="$(tput setaf 1)"
YELLOW="$(tput setaf 3)"
GREEN="$(tput setaf 2)"
BLUE="$(tput setaf 4)"
SKY_BLUE="$(tput setaf 6)"
RESET="$(tput sgr0)"

# Variables
Distro="Fedora-Hyprland"
Github_URL="https://github.com/LinuxBeginnings/$Distro.git"
Distro_DIR="$HOME/$Distro"

printf "\n%.0s" {1..1}

if ! command -v git &>/dev/null; then
    echo "${INFO} Git not found! ${SKY_BLUE}Installing Git...${RESET}"
    if ! sudo dnf install -y git; then
        echo "${ERROR} Failed to install Git. Exiting."
        exit 1
    fi
fi

printf "\n%.0s" {1..1}

if [ -d "$Distro_DIR" ]; then
    # Only replace a checkout of this repo. Deleting an unknown directory here
    # would take whatever else happens to live at that path with it.
    if [ ! -d "$Distro_DIR/.git" ]; then
        echo "${ERROR} $Distro_DIR exists but is not a git checkout of this repo."
        echo "${NOTE} Move or remove that directory yourself, then re-run this script."
        exit 1
    fi

    # Never silently discard local work
    if [ -n "$(git -C "$Distro_DIR" status --porcelain 2>/dev/null)" ]; then
        echo "${WARN} $Distro_DIR has local changes that a fresh clone would delete."
        echo "${NOTE} Commit or stash them, or remove the directory yourself, then re-run."
        exit 1
    fi

    echo "${YELLOW}$Distro_DIR exists. Removing and performing a fresh clone... ${RESET}"
    if ! rm -rf "$Distro_DIR"; then
        echo "${ERROR} Could not remove $Distro_DIR. Check permissions and try again."
        exit 1
    fi
else
    echo "${MAGENTA}$Distro_DIR does not exist. Cloning the repository...${RESET}"
fi

if ! git clone --depth=1 "$Github_URL" "$Distro_DIR"; then
    echo "${ERROR} Failed to clone $Github_URL. Check your network and try again."
    exit 1
fi

cd "$Distro_DIR" || { echo "${ERROR} Failed to change directory to $Distro_DIR"; exit 1; }
chmod +x install.sh || { echo "${ERROR} Failed to make install.sh executable"; exit 1; }
exec ./install.sh
