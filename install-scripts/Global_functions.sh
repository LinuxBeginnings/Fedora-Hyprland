#!/bin/bash
# ==================================================
#  KoolDots (2026)
#  Project URL: https://github.com/LinuxBeginnings
#  License: GNU GPLv3
#  SPDX-License-Identifier: GPL-3.0-or-later
# ==================================================
# 💫 https://github.com/KoolDots 💫 #
# Global Functions for Scripts #

# Install logs live under the repo root, never relative to the caller's cwd
LOG_DIR="${PARENT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}/Install-Logs"
mkdir -p "$LOG_DIR"

# Log file
LOG="$LOG_DIR/install.log"

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


# Show progress function
show_progress() {
    local pid=$1
    local package_name=$2
    local spin_chars=("●○○○○○○○○○" "○●○○○○○○○○" "○○●○○○○○○○" "○○○●○○○○○○" "○○○○●○○○○" \
                      "○○○○○●○○○○" "○○○○○○●○○○" "○○○○○○○●○○" "○○○○○○○○●○" "○○○○○○○○○●") 
    local i=0
    local status=0

    tput civis 
    printf "\r${INFO} Installing ${YELLOW}%s${RESET} ..." "$package_name"

    while ps -p "$pid" &> /dev/null; do
        printf "\r${INFO} Installing ${YELLOW}%s${RESET} %s" "$package_name" "${spin_chars[i]}"
        i=$(( (i + 1) % 10 ))  
        sleep 0.3  
    done

    wait "$pid"
    status=$?

    # 127 means the job was already reaped; the caller verifies with rpm anyway
    if [ "$status" -eq 127 ]; then
        status=0
    fi

    if [ "$status" -eq 0 ]; then
        printf "\r${OK} ${YELLOW}%s${RESET} install command finished.%-20s \n" "$package_name" ""
    else
        printf "\r${ERROR} ${YELLOW}%s${RESET} install command failed (exit %s).%-10s \n" "$package_name" "$status" ""
    fi
    tput cnorm  

    return "$status"
}

# Ask for the sudo password once, in the foreground, before any dnf runs in the
# background. Behind the spinner there is no visible password prompt, so an
# unprimed sudo timestamp looks exactly like a hung install.
prime_sudo() {
  if [ "${_SUDO_PRIMED:-0}" = "1" ]; then
    return 0
  fi
  if sudo -n true 2>/dev/null; then
    _SUDO_PRIMED=1
    return 0
  fi
  echo -e "${NOTE} sudo password is required to install packages. Enter it once if prompted."
  if sudo -v; then
    _SUDO_PRIMED=1
    return 0
  fi
  echo -e "${ERROR} Could not obtain sudo privileges. Nothing was installed."
  return 1
}

# Function to install packages
# Returns 0 when the package is installed, 1 when it could not be installed.
# Callers may pass their own log file as the second argument.
install_package() {
  local pkg="$1"
  local log="${2:-$LOG}"

  if rpm -q "$pkg" &>/dev/null ; then
    echo -e "${INFO} ${MAGENTA}$pkg${RESET} is already installed. Skipping..."
    return 0
  fi

  prime_sudo || return 1

  # Run dnf and redirect all output to a log file.
  # -n: fail fast rather than block on a password prompt nobody can see.
  (
    stdbuf -oL sudo -n dnf install -y "$pkg" 2>&1
  ) >> "$log" 2>&1 &
  local pid=$!

  # Keep the sudo timestamp fresh while dnf runs, so a long install does not
  # expire mid-way and fail with "sudo: a password is required"
  (
    while kill -0 "$pid" 2>/dev/null; do
      sleep 30
      sudo -n true 2>/dev/null || true
    done
  ) &
  local keepalive=$!

  show_progress "$pid" "$pkg"
  kill "$keepalive" 2>/dev/null || true

  # Double check if package is installed
  if rpm -q "$pkg" &>/dev/null ; then
    echo -e "${OK} Package ${YELLOW}$pkg${RESET} has been successfully installed!"
    return 0
  fi

  echo -e "\n${ERROR} ${YELLOW}$pkg${RESET} failed to install. Please check the $log. You may need to install manually."
  return 1
}

# Function for removing packages
uninstall_package() {
  local pkg="$1"

  # Checking if package is installed
  if rpm -q "$pkg" &>/dev/null; then
    echo -e "${NOTE} removing $pkg ..."
    sudo dnf remove -y "$pkg" 2>&1 | tee -a "$LOG" | grep -v "error: target not found"

    if ! rpm -q "$pkg" &>/dev/null; then
      echo -e "\e[1A\e[K${OK} $pkg removed."
    else
      echo -e "\e[1A\e[K${ERROR} $pkg Removal failed. No actions required."
      return 1
    fi
  else
    echo -e "${INFO} Package $pkg not installed, skipping."
  fi
  return 0
}