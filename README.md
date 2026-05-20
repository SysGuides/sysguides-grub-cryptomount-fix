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

## How This Script Fixes It

The script `99_cryptomount_check` is placed in `/etc/grub.d/`. Whenever `grub2-mkconfig` runs — whether triggered automatically by a Fedora update or run manually — it executes all scripts in that directory, including this one.

Here is what the script does each time it runs:

1. Detects the LUKS-encrypted block device backing `/` using `grub2-probe` and `cryptsetup`
2. Reads the LUKS UUID and converts it to the no-dash format required by GRUB
3. Checks whether `cryptomount -u <UUID_WITHOUT_DASHES>` is already the first line of `/boot/efi/EFI/fedora/grub.cfg`
4. If it is — does nothing
5. If it is missing, stale, or incorrect — removes any existing `cryptomount` lines and prepends the correct one

The `99_` prefix in the filename ensures this script runs **last**, after all other GRUB scripts have finished. This means it always checks and fixes the file at the end of every `grub2-mkconfig` run.

The fix is also **atomic** — it writes to a temporary file first and then replaces the original, so there is no risk of a half-written or corrupted `grub.cfg` if something goes wrong mid-operation.

> **Note on stdout/stderr:** Scripts in `/etc/grub.d/` have their stdout captured by `grub2-mkconfig` and written into the generated grub.cfg. This script redirects all output to stderr to avoid injecting anything unwanted into `/boot/grub2/grub.cfg`.

---

## Installation

### 1. Download the script

```bash
sudo wget -O /etc/grub.d/99_cryptomount_check \
  https://raw.githubusercontent.com/SysGuides/sysguides-grub-cryptomount-fix/main/99_cryptomount_check
```

### 2. Make it executable

`grub2-mkconfig` will only run scripts in `/etc/grub.d/` that are executable.

```bash
sudo chmod 755 /etc/grub.d/99_cryptomount_check
```

### 3. Test it manually

The script is safe to run at any time. It is idempotent — running it multiple times has no unintended side effects.

```bash
sudo bash /etc/grub.d/99_cryptomount_check
```

### 4. Verify the result

```bash
head -n 3 /boot/efi/EFI/fedora/grub.cfg
```

The first line should look like this:

```
cryptomount -u 563b9fdabd6a4c1497a37317d34818ea
```

(with your actual UUID, no dashes)

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
