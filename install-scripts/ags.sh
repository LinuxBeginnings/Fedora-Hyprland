#!/bin/bash
# ==================================================
#  KoolDots (2026)
#  Project URL: https://github.com/LinuxBeginnings
#  License: GNU GPLv3
#  SPDX-License-Identifier: GPL-3.0-or-later
# ==================================================
# 💫 https://github.com/KoolDots 💫 #
# Aylur's GTK Shell v 1.9.0 #
# for desktop overview

ags=(
	cmake
    typescript
    nodejs-npm
    meson
    gjs 
    gjs-devel
    gobject-introspection
    gobject-introspection-devel 
    gtk3-devel 
    gtk-layer-shell 
    upower 
    NetworkManager
    pam-devel 
    pulseaudio-libs-devel
    libdbusmenu-gtk3 
    libsoup3
)

# specific tags to download
ags_tag="v1.9.0"

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
LOG="Install-Logs/install-$(date +%d-%H%M%S)_ags.log"
MLOG="Install-Logs/install-$(date +%d-%H%M%S)_ags2.log"

# Check if AGS is installed
if command -v ags &>/dev/null; then
    AGS_VERSION=$(ags -v | awk '{print $NF}') 
    if [[ "$AGS_VERSION" == "1.9.0" ]]; then
        printf "${INFO} ${MAGENTA}Aylur's GTK Shell v1.9.0${RESET} is already installed. Skipping installation."
        printf "\n%.0s" {1..2}
        exit 0
    fi
fi

# Installation of main components
printf "\n%s - Installing ${SKY_BLUE}Aylur's GTK shell $ags_tag${RESET} Dependencies \n" "${NOTE}"

# Installing ags Dependencies
for PKG1 in "${ags[@]}"; do
    install_package "$PKG1" "$LOG"
done

printf "\n%.0s" {1..1}

# ags v1
printf "${NOTE} Install and Compiling ${SKY_BLUE}Aylur's GTK shell $ags_tag${RESET}..\n"

AGS_SRC_DIR="ags_v1.9.0"
# The old check removed a directory named "ags", but the clone lands in
# "ags_v1.9.0", so a second run failed with "destination path already exists"
if [ -d "$AGS_SRC_DIR" ]; then
    printf "${NOTE} Removing existing %s directory...\n" "$AGS_SRC_DIR"
    rm -rf "$AGS_SRC_DIR"
fi

printf "\n%.0s" {1..1}
printf "${INFO} Kindly Standby...cloning and compiling ${SKY_BLUE}Aylur's GTK shell $ags_tag${RESET}...\n"
printf "\n%.0s" {1..1}

# The KoolDots org was renamed to LinuxBeginnings; the old URL no longer exists,
# which made git sit on a "Username for 'https://github.com'" prompt instead of
# failing. GIT_TERMINAL_PROMPT=0 turns any future auth prompt into an error.
if ! GIT_TERMINAL_PROMPT=0 git clone --depth=1 https://github.com/LinuxBeginnings/ags_v1.9.0.git "$AGS_SRC_DIR" >> "$LOG" 2>&1; then
    echo -e "\n${ERROR} Failed to download ${YELLOW}Aylur's GTK shell $ags_tag${RESET} Please check your connection\n" 2>&1 | tee -a "$LOG"
    exit 1
fi

cd "$AGS_SRC_DIR" || { echo "${ERROR} Failed to enter $AGS_SRC_DIR"; exit 1; }

if ! npm install >> "$MLOG" 2>&1; then
    echo -e "\n${ERROR} npm install failed for ${YELLOW}AGS${RESET}. See $MLOG\n" 2>&1 | tee -a "$LOG"
    cd "$PARENT_DIR" || true
    exit 1
fi

if ! meson setup build >> "$MLOG" 2>&1; then
    echo -e "\n${ERROR} meson setup failed for ${YELLOW}AGS${RESET}. See $MLOG\n" 2>&1 | tee -a "$LOG"
    cd "$PARENT_DIR" || true
    exit 1
fi

# PIPESTATUS[0], not the pipeline status: `meson install | tee` reports tee's
# exit code, so a failed install looked successful
sudo meson install -C build 2>&1 | tee -a "$MLOG"
INSTALL_STATUS=${PIPESTATUS[0]}

cd "$PARENT_DIR" || true

# The old script never verified the binary, so a broken build reported success
if [ "$INSTALL_STATUS" -ne 0 ] || ! command -v ags >/dev/null 2>&1; then
    echo -e "\n${ERROR} ${YELLOW}Aylur's GTK shell $ags_tag${RESET} installation failed. See $MLOG\n " 2>&1 | tee -a "$LOG"
    exit 1
fi

printf "\n${OK} ${YELLOW}Aylur's GTK shell $ags_tag${RESET} installed successfully.\n" 2>&1 | tee -a "$MLOG"
printf "\n%.0s" {1..2}