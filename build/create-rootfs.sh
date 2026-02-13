#!/usr/bin/env bash
set -euo pipefail

SUITE="${SUITE:-trixie}"
ARCH="${ARCH:-amd64}"
MIRROR="${MIRROR:-http://deb.debian.org/debian}"
ROOTFS_DIR="${ROOTFS_DIR:-out/rootfs}"

if [[ "${EUID}" -ne 0 ]]; then
  echo "Run as root (or with sudo)."
  exit 1
fi

if ! command -v debootstrap >/dev/null 2>&1; then
  echo "debootstrap is required. Install it with: apt install debootstrap"
  exit 1
fi

mkdir -p "${ROOTFS_DIR}"

echo "[+] Bootstrapping Debian ${SUITE} (${ARCH}) into ${ROOTFS_DIR}"
debootstrap --arch="${ARCH}" "${SUITE}" "${ROOTFS_DIR}" "${MIRROR}"

echo "[+] Rootfs created at ${ROOTFS_DIR}"
