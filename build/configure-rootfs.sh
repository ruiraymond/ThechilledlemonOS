#!/usr/bin/env bash
set -euo pipefail

ROOTFS_DIR="${ROOTFS_DIR:-out/rootfs}"
HOSTNAME="${HOSTNAME:-thechilledlemon}"

if [[ "${EUID}" -ne 0 ]]; then
  echo "Run as root (or with sudo)."
  exit 1
fi

if [[ ! -d "${ROOTFS_DIR}" ]]; then
  echo "Rootfs not found: ${ROOTFS_DIR}"
  echo "Run ./build/create-rootfs.sh first"
  exit 1
fi

echo "[+] Configuring rootfs at ${ROOTFS_DIR}"

cat > "${ROOTFS_DIR}/etc/apt/sources.list" <<APT
deb http://deb.debian.org/debian trixie main contrib non-free-firmware
deb http://security.debian.org/debian-security trixie-security main contrib non-free-firmware
deb http://deb.debian.org/debian trixie-updates main contrib non-free-firmware
APT

echo "${HOSTNAME}" > "${ROOTFS_DIR}/etc/hostname"

echo "127.0.0.1 localhost" > "${ROOTFS_DIR}/etc/hosts"
echo "127.0.1.1 ${HOSTNAME}" >> "${ROOTFS_DIR}/etc/hosts"

mount --bind /dev "${ROOTFS_DIR}/dev"
mount --bind /proc "${ROOTFS_DIR}/proc"
mount --bind /sys "${ROOTFS_DIR}/sys"

cleanup() {
  umount -lf "${ROOTFS_DIR}/dev" || true
  umount -lf "${ROOTFS_DIR}/proc" || true
  umount -lf "${ROOTFS_DIR}/sys" || true
}
trap cleanup EXIT

chroot "${ROOTFS_DIR}" /bin/bash -c '
  set -e
  apt-get update
  DEBIAN_FRONTEND=noninteractive apt-get install -y \
    linux-image-amd64 \
    grub-pc \
    systemd-sysv \
    sudo \
    net-tools \
    network-manager \
    openssh-server \
    ca-certificates \
    locales \
    curl \
    vim

  echo "en_US.UTF-8 UTF-8" > /etc/locale.gen
  locale-gen
  update-locale LANG=en_US.UTF-8

  useradd -m -s /bin/bash chilledlemon || true
  echo "chilledlemon:chilledlemon" | chpasswd
  usermod -aG sudo chilledlemon

  systemctl enable NetworkManager
  systemctl enable ssh
'

echo "[+] Rootfs configured."
