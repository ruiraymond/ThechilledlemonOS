# ThechilledlemonOS

A lightweight custom Linux distribution scaffold based on **Debian 13 (Trixie)**.

This repository provides scripts to:

1. Bootstrap a Debian 13 root filesystem with `debootstrap`
2. Configure core packages and system defaults
3. Build a bootable raw disk image (`.img`)
4. Build a bootable live ISO image (`.iso`)

## Quick start

```bash
# 1) Build rootfs
sudo ./build/create-rootfs.sh

# 2) Customize rootfs (installs kernel + live boot packages)
sudo ./build/configure-rootfs.sh

# 3) Build bootable raw disk image
sudo ./build/make-image.sh

# 4) Build bootable live ISO image
sudo ./build/make-iso.sh
```

Artifacts are written to `out/`.

## Requirements

- Debian/Ubuntu host
- `debootstrap`
- `qemu-utils`
- `parted`
- `dosfstools`
- `e2fsprogs`
- `rsync`
- `squashfs-tools`
- `grub-pc-bin`
- `grub-efi-amd64-bin`
- `xorriso`
- `mtools`

Install required packages:

```bash
sudo apt update
sudo apt install -y \
  debootstrap qemu-utils parted dosfstools e2fsprogs rsync \
  squashfs-tools grub-pc-bin grub-efi-amd64-bin xorriso mtools
```

## Notes

- Default architecture is `amd64`
- Default Debian suite is `trixie` (Debian 13)
- You can override settings with environment variables (see scripts)
