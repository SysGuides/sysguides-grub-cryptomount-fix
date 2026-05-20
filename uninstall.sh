#!/bin/bash
# uninstall.sh — SysGuides GRUB Cryptomount Auto-Fix
# https://sysguides.com/

set -e

SCRIPT_NAME="uninstall.sh"

if [ "$EUID" -ne 0 ]; then
    echo "[${SCRIPT_NAME}] ERROR: Please run as root: sudo ./uninstall.sh"
    exit 1
fi

echo "[${SCRIPT_NAME}] Stopping and disabling cryptomount-check.path..."
systemctl disable --now cryptomount-check.path

echo "[${SCRIPT_NAME}] Removing systemd units..."
rm -f /etc/systemd/system/cryptomount-check.service
rm -f /etc/systemd/system/cryptomount-check.path
systemctl daemon-reload

echo "[${SCRIPT_NAME}] Removing /etc/grub.d/99_cryptomount_check..."
rm -f /etc/grub.d/99_cryptomount_check

echo ""
echo "[${SCRIPT_NAME}] Uninstall complete."
echo "[${SCRIPT_NAME}] Note: The cryptomount line in /boot/efi/EFI/fedora/grub.cfg was left intact."
