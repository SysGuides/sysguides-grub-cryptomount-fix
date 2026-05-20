# GRUB Cryptomount Auto-Fix for Fedora 44 Full Disk Encryption

Automatically ensures the required line:

```
cryptomount -u <UUID_WITHOUT_DASHES>
```

is always present as the **first line** of `/boot/efi/EFI/fedora/grub.cfg` after Fedora updates regenerate the file — preventing your system from dropping to a GRUB rescue prompt on reboot.

> **This script is a companion to a specific tutorial.** It is designed for the exact Fedora 44 full disk encryption setup described in the article and video below. If your setup is different, this script may not apply.
>
> - 📄 **Article:** [Fedora 44 Full Disk Encryption Setup](https://sysguides.com/)
> - 🎬 **YouTube Video:** [Watch on YouTube](https://youtube.com/)

---

## Background

### How Fedora normally handles encryption

Fedora's default LUKS encryption setup keeps `/boot` on a **separate, unencrypted ext4 partition**. GRUB reads the kernel and boot files directly from that unencrypted partition, so no special GRUB configuration is needed to unlock anything.

### This custom setup is different

This script is intended for a custom Fedora 44 full disk encryption setup where **there is no separate `/boot` partition**. Instead:

- `/boot` is a regular directory inside the LUKS-encrypted Btrfs root (`/`) partition
- GRUB itself must unlock the encrypted partition during early boot — before it can read any boot files
- The LUKS passphrase is entered at the GRUB prompt
- A second LUKS slot is configured for TPM2 auto-unlock

To make this work, GRUB needs the following line at the very beginning of `/boot/efi/EFI/fedora/grub.cfg`:

```
cryptomount -u <UUID_WITHOUT_DASHES>
```

This tells GRUB to unlock the LUKS partition (identified by UUID) before attempting to read anything else. Without it, GRUB cannot find the boot files and the system stops at a GRUB rescue prompt.

### The problem

Fedora does not natively support this full disk encryption layout. Because of this, certain kernel, GRUB, or system updates can cause Fedora to regenerate `/boot/efi/EFI/fedora/grub.cfg` — removing the `cryptomount` line in the process. The next reboot then fails.

---

## How This Fix Works

The solution has two parts that work together.

### Part 1 — The check script (`99_cryptomount_check`)

Placed in `/etc/grub.d/`, this script runs automatically whenever `grub2-mkconfig` is triggered. It detects the LUKS UUID dynamically, then checks and repairs the first line of `/boot/efi/EFI/fedora/grub.cfg` if needed.

The `99_` prefix ensures it runs **last**, after all other GRUB scripts have finished.

### Part 2 — The systemd path unit (`cryptomount-check.path`)

Some Fedora updates bypass `grub2-mkconfig` entirely and overwrite `/boot/efi/EFI/fedora/grub.cfg` directly. The `/etc/grub.d/` script alone cannot catch this.

The systemd path unit uses the kernel's inotify to **watch the `/boot/efi/EFI/fedora/` directory** for any changes. The moment the file is modified or replaced — by any process, at any time — it immediately triggers the check script to restore the `cryptomount` line.

Together, these two parts cover every scenario where the file can be overwritten.

> **Note on stdout/stderr:** Scripts in `/etc/grub.d/` have their stdout captured by `grub2-mkconfig` and written into the generated grub.cfg. The check script redirects all output to stderr to avoid injecting anything unwanted into `/boot/grub2/grub.cfg`.

---

## Files in This Repository

| File | Description |
|---|---|
| `99_cryptomount_check` | The main check and fix script, placed in `/etc/grub.d/` |
| `cryptomount-check.service` | Systemd service unit that runs the check script |
| `cryptomount-check.path` | Systemd path unit that watches for changes to grub.cfg |
| `install.sh` | Installs all files and enables the systemd units |
| `uninstall.sh` | Reverses the installation cleanly |

---

## Installation

### 1. Clone and install

```bash
sudo dnf install git -y
git clone https://github.com/SysGuides/sysguides-grub-cryptomount-fix.git
cd sysguides-grub-cryptomount-fix
chmod +x install.sh uninstall.sh
sudo ./install.sh
```

The installer will:

- Copy `99_cryptomount_check` to `/etc/grub.d/` and make it executable
- Install the systemd service and path units to `/etc/systemd/system/`
- Enable and start `cryptomount-check.path`
- Run the check script immediately to restore the `cryptomount` line if it is missing
- Print the first line of `/boot/efi/EFI/fedora/grub.cfg` so you can verify the result

### 2. Verify the result

```bash
sudo cat /boot/efi/EFI/fedora/grub.cfg
```

Expected output:

```
cryptomount -u 563b9fdabd6a4c1497a37317d34818ea
```

(with your actual UUID, no dashes)

### 3. Confirm the path unit is active

```bash
sudo systemctl status cryptomount-check.path
```

---

## Testing

To confirm the fix works end-to-end:

```bash
# Step 1 — Delete the cryptomount line
sudo sed -i '1{/^cryptomount/d;}' /boot/efi/EFI/fedora/grub.cfg

# Step 2 — Confirm it is gone
# In most cases, the cryptomount line is restored almost immediately,
# so this command may not show any visible change.
sudo cat /boot/efi/EFI/fedora/grub.cfg

# Step 3 — Wait a few seconds
sleep 3

# Step 4 — Confirm it is restored automatically
sudo cat /boot/efi/EFI/fedora/grub.cfg
```

The `cryptomount` line should reappear on its own within a few seconds.

---

## Uninstallation

```bash
cd sysguides-grub-cryptomount-fix
sudo ./uninstall.sh
```

This stops and removes the systemd units and the check script. The `cryptomount` line already present in `/boot/efi/EFI/fedora/grub.cfg` is left untouched.

---

## Compatibility

| | |
|---|---|
| **Distro** | Fedora 44 |
| **Firmware** | UEFI |
| **Encryption** | LUKS (full disk, no separate `/boot`) |
| **Filesystem** | Btrfs |
| **Auto-unlock** | TPM2 (second LUKS slot) |

---

## Related Content

- **Article:** Fedora 44 Full Disk Encryption Setup — https://sysguides.com/
- **YouTube Video:** https://youtube.com/

---

## License

Licensed under the [MIT License](LICENSE).
