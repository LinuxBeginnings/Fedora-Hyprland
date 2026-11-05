#!/bin/bash
# ==================================================
#  KoolDots (2026)
#  Project URL: https://github.com/LinuxBeginnings
#  License: GNU GPLv3
#  SPDX-License-Identifier: GPL-3.0-or-later
# ==================================================
# 💫 https://github.com/KoolDots 💫 #
# FONTS #

fonts=(
  adobe-source-code-pro-fonts
  fira-code-fonts
  fontawesome-fonts-all
  google-droid-sans-fonts
  google-noto-sans-cjk-fonts
  google-noto-color-emoji-fonts
  google-noto-emoji-fonts
  jetbrains-mono-fonts
)

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
LOG="Install-Logs/install-$(date +%d-%H%M%S)_fonts.log"


# Installation of main components
printf "\n%s - Installing necessary ${SKY_BLUE}fonts${RESET}.... \n" "${NOTE}"

font_failures=()
for PKG1 in "${fonts[@]}"; do
  install_package "$PKG1" || font_failures+=("$PKG1")
done
if [ ${#font_failures[@]} -gt 0 ]; then
  echo "${WARN} Font package(s) failed to install: ${font_failures[*]}" | tee -a "$LOG"
fi

printf "\n%.0s" {1..2}

# jetbrains nerd font. Necessary for waybar
DOWNLOAD_URL="https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.tar.xz"
# Maximum number of download attempts
MAX_ATTEMPTS=2
nerd_downloaded=0
nerd_font_ok=0
for ((ATTEMPT = 1; ATTEMPT <= MAX_ATTEMPTS; ATTEMPT++)); do
    # NOTE: no pipe to tee here. A pipeline reports the status of its last command,
    # so `curl ... | tee` would look successful even when curl failed.
    if curl -fL -o JetBrainsMono.tar.xz "$DOWNLOAD_URL" >> "$LOG" 2>&1; then
        nerd_downloaded=1
        break
    fi
    echo "Download ${YELLOW}DOWNLOAD_URL${RESET} attempt $ATTEMPT failed. Retrying in 2 seconds..." 2>&1 | tee -a "$LOG"
    sleep 2
done

# Check if the JetBrainsMono directory exists and delete it if it does
if [ -d ~/.local/share/fonts/JetBrainsMonoNerd ]; then
    rm -rf ~/.local/share/fonts/JetBrainsMonoNerd 2>&1 | tee -a "$LOG"
fi

mkdir -p ~/.local/share/fonts/JetBrainsMonoNerd
# Extract the new files into the JetBrainsMono directory and log the output
if [ "$nerd_downloaded" -eq 1 ] && tar -xJkf JetBrainsMono.tar.xz -C ~/.local/share/fonts/JetBrainsMonoNerd >> "$LOG" 2>&1; then
    nerd_font_ok=1
else
    echo -e "\n${ERROR} ${YELLOW}JetBrainsMono Nerd Font${RESET} could not be installed. waybar icons may not render.\n" | tee -a "$LOG"
fi

# clean up 
if [ -f "JetBrainsMono.tar.xz" ]; then
	rm -f JetBrainsMono.tar.xz 2>&1 | tee -a "$LOG"
fi

# Fantasque Mono Nerd Font
# Extract into the directory that is actually created: the old line made
# .../FantasqueSansMonoNerd but unzipped into .../FantasqueSansMono
FANTASQUE_DIR="$HOME/.local/share/fonts/FantasqueSansMonoNerd"
if wget -q -O FantasqueSansMono.zip https://github.com/ryanoasis/nerd-fonts/releases/download/v3.3.0/FantasqueSansMono.zip \
   && mkdir -p "$FANTASQUE_DIR" \
   && unzip -o -q FantasqueSansMono.zip -d "$FANTASQUE_DIR" >> "$LOG" 2>&1; then
    rm -f FantasqueSansMono.zip
    echo "${OK} FantasqueSansMono installed to $FANTASQUE_DIR" | tee -a "$LOG"
else
    rm -f FantasqueSansMono.zip
    echo -e "\n${ERROR} Failed to install ${YELLOW}Fantasque Sans Mono Nerd Font${RESET} Please check your connection\n" | tee -a "$LOG"
fi

# Victor Mono-Font
if wget -q https://rubjo.github.io/victor-mono/VictorMonoAll.zip; then
    mkdir -p "$HOME/.local/share/fonts/VictorMono" && unzip -o -q "VictorMonoAll.zip" -d "$HOME/.local/share/fonts/VictorMono" && echo "Victor Font installed successfully" | tee -a "$LOG"
else
    echo -e "\n${ERROR} Failed to download ${YELLOW}Victor Mono Font${RESET} Please check your connection\n" | tee -a "$LOG"
fi

# Update font cache and log the output
fc-cache -v 2>&1 | tee -a "$LOG"

if [ "$nerd_font_ok" -ne 1 ]; then
    echo -e "${ERROR} The JetBrains Nerd Font is required by waybar. Install it manually, then re-run the installer." | tee -a "$LOG"
    exit 1
fi

printf "\n%.0s" {1..2}