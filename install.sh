#!/bin/bash
# install.sh — SysGuides GRUB Cryptomount Auto-Fix
# https://sysguides.com/

set -e

SCRIPT_NAME="install.sh"

if [ "$EUID" -ne 0 ]; then
    echo "[${SCRIPT_NAME}] ERROR: Please run as root: sudo ./install.sh"
    exit 1
fi

echo "[${SCRIPT_NAME}] Installing 99_cryptomount_check..."
cp 99_cryptomount_check /etc/grub.d/99_cryptomount_check
chmod 755 /etc/grub.d/99_cryptomount_check

echo "[${SCRIPT_NAME}] Installing systemd units..."
cp cryptomount-check.service /etc/systemd/system/cryptomount-check.service
cp cryptomount-check.path /etc/systemd/system/cryptomount-check.path

echo "[${SCRIPT_NAME}] Enabling and starting cryptomount-check.path..."
systemctl daemon-reload
systemctl enable --now cryptomount-check.path

echo "[${SCRIPT_NAME}] Running initial cryptomount check..."
bash /etc/grub.d/99_cryptomount_check

echo ""
echo "[${SCRIPT_NAME}] Installation complete."
echo "[${SCRIPT_NAME}] Verifying /boot/efi/EFI/fedora/grub.cfg first line:"
head -n 1 /boot/efi/EFI/fedora/grub.cfg
