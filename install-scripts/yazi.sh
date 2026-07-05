#!/usr/bin/env bash
# ==================================================
#  KoolDots (2026)
#  Project URL: https://github.com/LinuxBeginnings
#  License: GNU GPLv3
#  SPDX-License-Identifier: GPL-3.0-or-later
# ==================================================
# 💫 https://github.com/KoolDots 💫 #
# Install/Update Yazi for Fedora

MIN_YAZI_VERSION="26.5.0"

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
LOG="Install-Logs/install-$(date +%d-%H%M%S)_yazi.log"

version_ge() {
  [ "$(printf '%s\n' "$2" "$1" | sort -V | head -n1)" = "$2" ]
}

get_yazi_version() {
  rpm -q --qf '%{VERSION}' yazi 2>/dev/null
}

remove_local_yazi_bins() {
  local removed=0
  for bin in yazi ya; do
    if [ -e "/usr/local/bin/$bin" ]; then
      sudo rm -f "/usr/local/bin/$bin"
      echo "${NOTE} Removed /usr/local/bin/$bin" | tee -a "$LOG"
      removed=1
    fi
  done

  if [ "$removed" -eq 0 ]; then
    echo "${INFO} No manual Yazi binaries found in /usr/local/bin." | tee -a "$LOG"
  fi
}

needs_install=0

if rpm -q yazi &>/dev/null; then
  current_version="$(get_yazi_version)"
  if [ -n "$current_version" ] && version_ge "$current_version" "$MIN_YAZI_VERSION"; then
    echo "${OK} yazi $current_version is installed (>= $MIN_YAZI_VERSION)." | tee -a "$LOG"
  else
    echo "${WARN} yazi version is ${current_version:-unknown}. Expected >= $MIN_YAZI_VERSION." | tee -a "$LOG"
    needs_install=1
  fi
else
  echo "${WARN} yazi is not installed." | tee -a "$LOG"
  needs_install=1
fi

remove_local_yazi_bins

if [ "$needs_install" -eq 1 ]; then
  echo "${NOTE} Installing/updating yazi..." | tee -a "$LOG"
  (
    stdbuf -oL sudo dnf install -y yazi 2>&1
  ) >> "$LOG" 2>&1 &
  PID=$!
  show_progress $PID "yazi"

  if rpm -q yazi &>/dev/null; then
    updated_version="$(get_yazi_version)"
    if [ -n "$updated_version" ] && version_ge "$updated_version" "$MIN_YAZI_VERSION"; then
      echo "${OK} yazi $updated_version is installed (>= $MIN_YAZI_VERSION)." | tee -a "$LOG"
    else
      echo "${WARN} yazi version is ${updated_version:-unknown}. Expected >= $MIN_YAZI_VERSION." | tee -a "$LOG"
    fi
  else
    echo "${ERROR} yazi failed to install. Please check the $LOG." | tee -a "$LOG"
  fi
fi
