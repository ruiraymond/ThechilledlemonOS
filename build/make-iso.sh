#!/usr/bin/env bash
set -euo pipefail

ROOTFS_DIR="${ROOTFS_DIR:-out/rootfs}"
ISO_PATH="${ISO_PATH:-out/thechilledlemonos.iso}"
WORK_DIR="${WORK_DIR:-out/iso-work}"
ISO_VOLUME_ID="${ISO_VOLUME_ID:-THECHILLEDMONOS_13}"

REQUIRED_CMDS=(mksquashfs grub-mkstandalone xorriso mkfs.vfat mmd mcopy truncate)

if [[ "${EUID}" -ne 0 ]]; then
  echo "Run as root (or with sudo)."
  exit 1
fi

if [[ ! -d "${ROOTFS_DIR}" ]]; then
  echo "Rootfs not found: ${ROOTFS_DIR}"
  echo "Run ./build/create-rootfs.sh and ./build/configure-rootfs.sh first"
  exit 1
fi

for cmd in "${REQUIRED_CMDS[@]}"; do
  if ! command -v "${cmd}" >/dev/null 2>&1; then
    echo "Missing required command: ${cmd}"
    echo "Install dependencies: apt install squashfs-tools grub-pc-bin grub-efi-amd64-bin xorriso"
    exit 1
  fi
done

if [[ ! -f "${ROOTFS_DIR}/boot/vmlinuz" ]] || [[ ! -f "${ROOTFS_DIR}/boot/initrd.img" ]]; then
  echo "Kernel or initrd missing in ${ROOTFS_DIR}/boot"
  echo "Ensure the rootfs has linux-image-amd64 and initramfs-tools installed"
  exit 1
fi

mkdir -p "$(dirname "${ISO_PATH}")"
rm -rf "${WORK_DIR}"
mkdir -p \
  "${WORK_DIR}/iso/live" \
  "${WORK_DIR}/iso/boot/grub" \
  "${WORK_DIR}/tmp"

echo "[+] Preparing kernel and initramfs"
cp "${ROOTFS_DIR}/boot/vmlinuz" "${WORK_DIR}/iso/live/vmlinuz"
cp "${ROOTFS_DIR}/boot/initrd.img" "${WORK_DIR}/iso/live/initrd.img"

echo "[+] Creating SquashFS from rootfs"
mksquashfs "${ROOTFS_DIR}" "${WORK_DIR}/iso/live/filesystem.squashfs" \
  -e boot \
  -comp xz \
  -wildcards

cat > "${WORK_DIR}/iso/boot/grub/grub.cfg" <<'GRUBCFG'
set default=0
set timeout=5

menuentry "ThechilledlemonOS (Debian 13 Live)" {
    linux /live/vmlinuz boot=live components quiet
    initrd /live/initrd.img
}
GRUBCFG

echo "[+] Building standalone UEFI GRUB image"
grub-mkstandalone \
  -O x86_64-efi \
  -o "${WORK_DIR}/tmp/bootx64.efi" \
  "boot/grub/grub.cfg=${WORK_DIR}/iso/boot/grub/grub.cfg"

# Create FAT image for EFI bootloader.
truncate -s 10M "${WORK_DIR}/tmp/efiboot.img"
mkfs.vfat "${WORK_DIR}/tmp/efiboot.img" >/dev/null
mmd -i "${WORK_DIR}/tmp/efiboot.img" ::/EFI ::/EFI/BOOT
mcopy -i "${WORK_DIR}/tmp/efiboot.img" "${WORK_DIR}/tmp/bootx64.efi" ::/EFI/BOOT/BOOTX64.EFI

cp "${WORK_DIR}/tmp/efiboot.img" "${WORK_DIR}/iso/boot/grub/efiboot.img"

echo "[+] Building hybrid ISO at ${ISO_PATH}"
xorriso -as mkisofs \
  -iso-level 3 \
  -full-iso9660-filenames \
  -volid "${ISO_VOLUME_ID}" \
  -eltorito-boot boot/grub/efiboot.img \
    -no-emul-boot \
    -eltorito-alt-boot \
  -e boot/grub/efiboot.img \
    -no-emul-boot \
  -append_partition 2 0xef "${WORK_DIR}/tmp/efiboot.img" \
  -output "${ISO_PATH}" \
  "${WORK_DIR}/iso"

echo "[+] ISO image created: ${ISO_PATH}"
