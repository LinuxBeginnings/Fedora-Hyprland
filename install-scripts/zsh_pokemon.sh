#!/bin/bash
# ==================================================
#  KoolDots (2026)
#  Project URL: https://github.com/LinuxBeginnings
#  License: GNU GPLv3
#  SPDX-License-Identifier: GPL-3.0-or-later
# ==================================================
# 💫 https://github.com/KoolDots 💫 #
# pokemon-color-scripts#

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

# Set the name of the log file to include the current date and time
LOG="$LOG_DIR/install-$(date +%d-%H%M%S)_zsh_pokemon.log"

printf "${INFO} Installing ${SKY_BLUE}Pokemon color scripts${RESET} ..."

# Clone into the user's data dir, not the repo root (it used to leave an
# untracked pokemon-colorscripts/ directory inside the installer checkout)
POKEMON_DIR="$HOME/.local/share/pokemon-colorscripts"

if [ -d "$POKEMON_DIR/.git" ]; then
    if ! git -C "$POKEMON_DIR" pull --ff-only >> "$LOG" 2>&1; then
        echo "${WARN} Could not update pokemon-colorscripts, using the existing copy." | tee -a "$LOG"
    fi
else
    mkdir -p "$(dirname "$POKEMON_DIR")"
    rm -rf "$POKEMON_DIR"
    if ! git clone --depth=1 https://gitlab.com/phoneybadger/pokemon-colorscripts.git "$POKEMON_DIR" >> "$LOG" 2>&1; then
        echo "${ERROR} Failed to download pokemon-colorscripts. Please check your connection." | tee -a "$LOG"
    fi
fi

if [ -f "$POKEMON_DIR/install.sh" ]; then
    if ! ( cd "$POKEMON_DIR" && sudo ./install.sh ) >> "$LOG" 2>&1; then
        echo "${ERROR} pokemon-colorscripts installer failed. See $LOG" | tee -a "$LOG"
    fi
else
    echo "${ERROR} pokemon-colorscripts is missing, skipping its installer." | tee -a "$LOG"
fi

# Check if ~/.zshrc exists
if [ -f "$HOME/.zshrc" ]; then
	sed -i 's|^#pokemon-colorscripts --no-title -s -r \| fastfetch -c \$HOME/.config/fastfetch/config-pokemon.jsonc --logo-type file-raw --logo-height 10 --logo-width 5 --logo -|pokemon-colorscripts --no-title -s -r \| fastfetch -c \$HOME/.config/fastfetch/config-pokemon.jsonc --logo-type file-raw --logo-height 10 --logo-width 5 --logo -|' "$HOME/.zshrc" >> "$LOG" 2>&1
	sed -i "s|^fastfetch -c \$HOME/.config/fastfetch/config-compact.jsonc|#fastfetch -c \$HOME/.config/fastfetch/config-compact.jsonc|" "$HOME/.zshrc" >> "$LOG" 2>&1
else
    echo "$HOME/.zshrc not found. Cant enable ${YELLOW}Pokemon color scripts${RESET}" >> "$LOG" 2>&1
fi
  
printf "\n%.0s" {1..2}
