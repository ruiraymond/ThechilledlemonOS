# ThechilledlemonOS

A lightweight custom Linux distribution scaffold based on **Debian 13 (Trixie)**.

This repository provides scripts to:

1. Bootstrap a Debian 13 root filesystem with `debootstrap`
2. Configure core packages and system defaults
3. Assemble a bootable disk image from the generated rootfs

## Quick start

```bash
# 1) Build rootfs
sudo ./build/create-rootfs.sh

# 2) Customize rootfs
sudo ./build/configure-rootfs.sh

# 3) Build bootable image
sudo ./build/make-image.sh
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

Install required packages:

```bash
sudo apt update
sudo apt install -y debootstrap qemu-utils parted dosfstools e2fsprogs rsync
```

## Notes

- Default architecture is `amd64`
- Default Debian suite is `trixie` (Debian 13)
- You can override settings with environment variables (see scripts)
