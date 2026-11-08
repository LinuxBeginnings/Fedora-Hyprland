#!/bin/bash
# ==================================================
#  KoolDots (2026)
#  Project URL: https://github.com/LinuxBeginnings
#  License: GNU GPLv3
#  SPDX-License-Identifier: GPL-3.0-or-later
# ==================================================
# 💫 https://github.com/KoolDots 💫 #
# ZSH and oh-my-zsh #

zsh=(
  lsd
  fzf
  mercurial
  zsh 
  util-linux
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
LOG="$LOG_DIR/install-$(date +%d-%H%M%S)_zsh.log"

# Check if the log file already exists, if yes, append a counter to make it unique
COUNTER=1
while [ -f "$LOG" ]; do
  LOG="$LOG_DIR/install-$(date +%d-%H%M%S)_${COUNTER}_zsh.log"
  ((COUNTER++))
done

# Installing zsh packages
printf "${NOTE} Installing core zsh packages...${RESET}\n"
for ZSHP in "${zsh[@]}"; do
  install_package "$ZSHP"
done

printf "\n%.0s" {1..1}

# Install Oh My Zsh, plugins, and set zsh as default shell
if command -v zsh >/dev/null; then
  printf "${NOTE} Installing ${SKY_BLUE}Oh My Zsh and plugins${RESET} ...\n"
  if [ ! -d "$HOME/.oh-my-zsh" ]; then  
    if ! sh -c "$(curl -fsSL https://install.ohmyz.sh)" "" --unattended; then
      echo "${ERROR} Oh My Zsh installation failed. Check $LOG and re-run." | tee -a "$LOG"
    fi  	       
  else
    echo "${INFO} Directory .oh-my-zsh already exists. Skipping re-installation." 2>&1 | tee -a "$LOG"
  fi
  
  # Check if the directories exist before cloning the repositories
  if [ ! -d "$HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions" ]; then
      git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions 
  else
      echo "${INFO} Directory zsh-autosuggestions already exists. Cloning Skipped." 2>&1 | tee -a "$LOG"
  fi

  if [ ! -d "$HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting" ]; then
      git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting 
  else
      echo "${INFO} Directory zsh-syntax-highlighting already exists. Cloning Skipped." 2>&1 | tee -a "$LOG"
  fi
  
  # Check if ~/.zshrc and .zprofile exists, create a backup, and copy the new configuration
  if [ -f "$HOME/.zshrc" ]; then
      cp -b "$HOME/.zshrc" "$HOME/.zshrc-backup" || true
  fi

  if [ -f "$HOME/.zprofile" ]; then
      cp -b "$HOME/.zprofile" "$HOME/.zprofile-backup" || true
  fi
  
  # Copying the preconfigured zsh themes and profile
  cp -r 'assets/.zshrc' ~/
  cp -r 'assets/.zprofile' ~/

  # Check if the current shell is zsh
  current_shell=$(basename "$SHELL")
  if [ "$current_shell" != "zsh" ]; then
    printf "${NOTE} Changing default shell to ${MAGENTA}zsh${RESET}..."
    printf "\n%.0s" {1..2}

    # Try a few times, then give up: an unbounded loop here traps the user
    # until they get the password right, with no way to skip.
    CHSH_OK=0
    for attempt in 1 2 3; do
      if chsh -s "$(command -v zsh)"; then
        CHSH_OK=1
        break
      fi
      echo "${ERROR} chsh failed (attempt ${attempt}/3). Please enter the correct password." 2>&1 | tee -a "$LOG"
      [ "$attempt" -lt 3 ] && sleep 1
    done

    if [ "$CHSH_OK" -eq 1 ]; then
      printf "${INFO} Shell changed successfully to ${MAGENTA}zsh${RESET}" 2>&1 | tee -a "$LOG"
    else
      echo "${WARN} Could not change your default shell. Run manually: chsh -s $(command -v zsh)" 2>&1 | tee -a "$LOG"
    fi
  else
    echo "${NOTE} Your shell is already set to ${MAGENTA}zsh${RESET}."
  fi

fi

# copy additional oh-my-zsh themes from assets
if [ -d "$HOME/.oh-my-zsh/themes" ]; then
    cp -r assets/add_zsh_theme/* ~/.oh-my-zsh/themes >> "$LOG" 2>&1
fi

printf "\n%.0s" {1..2}

