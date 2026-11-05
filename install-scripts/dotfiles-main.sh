#!/bin/bash
# ==================================================
#  KoolDots (2026)
#  Project URL: https://github.com/LinuxBeginnings
#  License: GNU GPLv3
#  SPDX-License-Identifier: GPL-3.0-or-later
# ==================================================
# 💫 https://github.com/KoolDots 💫 #
# Hyprland-Dots to download from main #

## WARNING: DO NOT EDIT BEYOND THIS LINE IF YOU DON'T KNOW WHAT YOU ARE DOING! ##
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Change the working directory to the parent directory of the script
PARENT_DIR="$SCRIPT_DIR/.."
cd "$PARENT_DIR" || { echo "${ERROR} Failed to change directory to $PARENT_DIR"; exit 1; }

# Source the global functions script
if ! source "$(dirname "$(readlink -f "$0")")/Global_functions.sh"; then
  echo "Failed to source Global_functions.sh"
  exit 1
fi


printf "${NOTE} Cloning and Installing ${SKY_BLUE}KooL's Hyprland Dots${RESET}....\n"
install_failed=0

# Check if Hyprland-Dots exists
if [ -d Hyprland-Dots ]; then
  cd Hyprland-Dots || { echo -e "${ERROR} Cannot enter Hyprland-Dots"; exit 1; }
  git stash >/dev/null 2>&1 || true
  if ! git pull; then
    echo -e "${WARN} Could not update Hyprland-Dots. Using the existing copy." | tee -a "$LOG"
  fi
  chmod +x copy.sh
  if ! ./copy.sh; then
    echo -e "${ERROR} copy.sh failed. Dotfiles were not installed correctly." | tee -a "$LOG"
    install_failed=1
  fi
  cd ..
else
  if git clone --depth=1 https://github.com/LinuxBeginnings/Hyprland-Dots; then
    cd Hyprland-Dots || { echo -e "${ERROR} Cannot enter Hyprland-Dots"; exit 1; }
    chmod +x copy.sh
    if ! ./copy.sh; then
      echo -e "${ERROR} copy.sh failed. Dotfiles were not installed correctly." | tee -a "$LOG"
      install_failed=1
    fi
    cd ..
  else
    echo -e "$ERROR Can't download ${YELLOW}KooL's Hyprland Dots${RESET} . Check your internet connection" | tee -a "$LOG"
    install_failed=1
  fi
fi

if [ "$install_failed" -ne 0 ]; then
  exit 1
fi

printf "\n%.0s" {1..2}
