#!/usr/bin/env bash
set -euo pipefail

ROOTFS_DIR="${ROOTFS_DIR:-out/rootfs}"
IMAGE_PATH="${IMAGE_PATH:-out/thechilledlemonos.img}"
IMAGE_SIZE_MB="${IMAGE_SIZE_MB:-4096}"
MOUNT_DIR="${MOUNT_DIR:-out/mnt}"

if [[ "${EUID}" -ne 0 ]]; then
  echo "Run as root (or with sudo)."
  exit 1
fi

if [[ ! -d "${ROOTFS_DIR}" ]]; then
  echo "Rootfs not found: ${ROOTFS_DIR}"
  echo "Run create-rootfs.sh and configure-rootfs.sh first"
  exit 1
fi

mkdir -p "$(dirname "${IMAGE_PATH}")" "${MOUNT_DIR}"

echo "[+] Creating ${IMAGE_SIZE_MB}MB raw image at ${IMAGE_PATH}"
qemu-img create -f raw "${IMAGE_PATH}" "${IMAGE_SIZE_MB}M"

LOOP_DEV=$(losetup --find --show --partscan "${IMAGE_PATH}")
cleanup() {
  umount -lf "${MOUNT_DIR}" || true
  losetup -d "${LOOP_DEV}" || true
}
trap cleanup EXIT

echo "[+] Partitioning image"
parted -s "${LOOP_DEV}" mklabel msdos
parted -s "${LOOP_DEV}" mkpart primary ext4 1MiB 100%

mkfs.ext4 -F "${LOOP_DEV}p1"
mount "${LOOP_DEV}p1" "${MOUNT_DIR}"

echo "[+] Copying rootfs"
rsync -aHAX --numeric-ids "${ROOTFS_DIR}/" "${MOUNT_DIR}/"

for d in dev proc sys; do
  mount --bind "/${d}" "${MOUNT_DIR}/${d}"
done

chroot "${MOUNT_DIR}" grub-install --target=i386-pc --recheck "${LOOP_DEV}"
chroot "${MOUNT_DIR}" update-grub

for d in dev proc sys; do
  umount -lf "${MOUNT_DIR}/${d}" || true
done

echo "[+] Bootable image created: ${IMAGE_PATH}"
