#!/usr/bin/env bash
# ==================================================
#  KoolDots (2026)
#  Project URL: https://github.com/LinuxBeginnings
#  License: GNU GPLv3
#  SPDX-License-Identifier: GPL-3.0-or-later
# ==================================================
# 💫 https://github.com/LinuxBeginnings 💫 #
#

set -o pipefail

HYPRMOD_INSTALL_URL="https://raw.githubusercontent.com/BlueManCZ/hyprmod/main/install.sh"

show_help() {
	cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Install, update, or uninstall hyprmod.

Options:
  -h, --help        Show this help message
  -u, --uninstall   Uninstall hyprmod
  -U, --update      Update hyprmod to the latest version

Without options, this script installs hyprmod if it is not already installed.

EOF
}

msg() {
	printf '%s\n' "$1"
}

error() {
	printf 'ERROR: %s\n' "$1" >&2
}

require_command() {
	if ! command -v "$1" >/dev/null 2>&1; then
		error "Required command '$1' was not found."
		return 1
	fi
}

hyprmod_installed() {
	command -v hyprmod >/dev/null 2>&1
}

run_hyprmod_installer() {
	local action="${1:-install}"

	require_command curl || return 1
	require_command sh || return 1

	case "$action" in
		install|update)
			curl -LsSf "$HYPRMOD_INSTALL_URL" | sh
			;;
		uninstall)
			curl -LsSf "$HYPRMOD_INSTALL_URL" | sh -s -- --uninstall
			;;
		*)
			error "Unknown installer action: $action"
			return 1
			;;
	esac
}

install_hyprmod() {
	if hyprmod_installed; then
		msg "hyprmod is already installed."
		return 0
	fi

	msg "Installing hyprmod..."
	if run_hyprmod_installer install; then
		msg "hyprmod installed successfully."
	else
		error "hyprmod installation failed."
		return 1
	fi
}

update_hyprmod() {
	msg "Updating hyprmod..."
	if run_hyprmod_installer update; then
		msg "hyprmod update completed successfully."
	else
		error "hyprmod update failed."
		return 1
	fi
}

uninstall_hyprmod() {
	if ! hyprmod_installed; then
		msg "hyprmod is not installed."
		return 0
	fi

	msg "Uninstalling hyprmod..."
	if run_hyprmod_installer uninstall; then
		msg "hyprmod uninstalled successfully."
	else
		error "hyprmod uninstall failed."
		return 1
	fi
}

case "${1:-}" in
	"")
		install_hyprmod
		;;
	-h|--help)
		show_help
		;;
	-u|--uninstall)
		uninstall_hyprmod
		;;
	-U|--update)
		update_hyprmod
		;;
	*)
		error "Unknown option: $1"
		show_help
		exit 1
		;;
esac
