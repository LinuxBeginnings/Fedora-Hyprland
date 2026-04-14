#!/bin/bash
# ==================================================
#  KoolDots (2026)
#  Project URL: https://github.com/LinuxBeginnings
#  License: GNU GPLv3
#  SPDX-License-Identifier: GPL-3.0-or-later
# ==================================================
# 💫 https://github.com/KoolDots 💫 #
# Hyprland-Dots Packages #
# edit your packages desired here.
# WARNING! If you remove packages here, dotfiles may not work properly.
# and also, ensure that packages are present in fedora repo or add copr repo

# add packages wanted here
Extra=(

)

# packages neeeded
hypr_package=(
    bc
    curl
    findutils
    gawk
    git
    grim
    gvfs
    gvfs-mtp
    hyprpolkitagent
    ImageMagick
    inxi
    jq
    kitty
    kvantum
    kvantum-qt5
    qt5-qtdeclarative
    qt5-qtquickcontrols2
    qt6-qtdeclarative
    nano
    network-manager-applet
    openssl
    pamixer
    pavucontrol
    pipewire-alsa
    pipewire-utils
    pulseaudio-utils
    playerctl
    python3-requests
    python3-pip
    python3-pyquery
    qt5ct
    qt6ct
    qt6-qtsvg
    rsync
    rofi
    slurp
    swappy
    unzip # required later
    uwsm  # In case use logins with UWSM managed option
    waybar
    wget2
    wl-clipboard
    wlogout
    xfce-polkit
    xdg-user-dirs
    xdg-utils
    yad
)

# the following packages can be deleted. however, dotfiles may not work properly
hypr_package_2=(
    brightnessctl
    btop
    cava
    loupe
    fastfetch
    gnome-system-monitor
    mousepad
    mpv
    mpv-mpris
    nvtop
    qalculate-gtk
)

copr_packages=(
    nwg-displays
    cliphist
    nwg-look
    SwayNotificationCenter
    pamixer
    swww
    wallust
)

# List of packages to uninstall as it conflicts some packages
uninstall=(
    aylurs-gtk-shell
    dunst
    mako
    rofi
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
LOG="Install-Logs/install-$(date +%d-%H%M%S)_hypr-pkgs.log"
# Check rofi presence and version (skip if >= 2.00)
skip_rofi=false
if rpm -q rofi &>/dev/null; then
    rofi_version=$(rpm -q --qf '%{VERSION}' rofi 2>/dev/null)
    if [ -n "$rofi_version" ] && [ "$(printf '%s\n' "2.00" "$rofi_version" | sort -V | head -n1)" = "2.00" ]; then
        skip_rofi=true
        echo "${NOTE} Rofi $rofi_version detected (>= 2.00). Skipping removal/reinstall." | tee -a "$LOG"
    fi
fi

# conflicting packages removal
overall_failed=0
printf "\n%s - ${SKY_BLUE}Removing some packages${RESET} as it conflicts with KooL's Hyprland Dots \n" "${NOTE}"
for PKG in "${uninstall[@]}"; do
    if [ "$PKG" = "rofi" ] && [ "$skip_rofi" = "true" ]; then
        continue
    fi
    uninstall_package "$PKG" 2>&1 | tee -a "$LOG"
    if [ $? -ne 0 ]; then
        overall_failed=1
    fi
done

if [ $overall_failed -ne 0 ]; then
    echo -e "${ERROR} Some packages failed to uninstall. Please check the log."
fi

printf "\n%.0s" {1..1}

# Installation of main components
printf "\n%s - Installing ${SKY_BLUE}KooL's hyprland necessary packages${RESET} .... \n" "${NOTE}"

for PKG1 in "${hypr_package[@]}" "${hypr_package_2[@]}" "${copr_packages[@]}" "${Extra[@]}"; do
    if [ "$PKG1" = "rofi" ] && [ "$skip_rofi" = "true" ]; then
        continue
    fi
    install_package "$PKG1" "$LOG"
done

printf "\n%.0s" {1..2}
