#!/usr/bin/env bash

set -euo pipefail

PROGRAM_NAME="dnfmgr"
CONFIG_DIR="$HOME/.config/$PROGRAM_NAME"

mkdir -p "$CONFIG_DIR"
PACKAGES_FILE="$CONFIG_DIR/packages"
MANAGED_PACKAGES_FILE="$CONFIG_DIR/.managed-packages"

touch "$PACKAGES_FILE"
touch "$MANAGED_PACKAGES_FILE"

new_packages=$(sort "$PACKAGES_FILE")
old_packages=$(sort "$MANAGED_PACKAGES_FILE")

mapfile -t added < <(comm -13 <(echo "$old_packages") <(echo "$new_packages"))
mapfile -t removed < <(comm -23 <(echo "$old_packages") <(echo "$new_packages"))

printf "added: "
printf "%s " "${added[@]}"

printf "\n\nremoved: "
printf "%s " "${removed[@]}"

printf "\n\n"

if [ "${#added[@]}" -gt 0 ]; then
	printf "Installing...\n"
	if ! sudo dnf install -y "${added[@]}"; then
		echo "Failed to install packages" >&2
		exit 1
	fi
fi

if [ "${#removed[@]}" -gt 0 ]; then
	printf "Removing...\n"
	if ! sudo dnf remove -y "${removed[@]}"; then
		echo "Failed to remove packages" >&2
		exit 1
	fi
fi

printf "Cleaning things up...\n"
sudo dnf autoremove -y

printf "Updating stuff...\n"
sudo dnf update -y

cp "$MANAGED_PACKAGES_FILE" "$MANAGED_PACKAGES_FILE".bak
cp "$PACKAGES_FILE" "$MANAGED_PACKAGES_FILE"
