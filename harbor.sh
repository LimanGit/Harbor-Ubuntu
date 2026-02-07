#!/bin/sh

#############################
# Debian/Ubuntu Lite Install #
#############################

ROOTFS_DIR=/home/container
DISTRO="debian"             # can also use "ubuntu"
RELEASE="bookworm"          # Debian slim release
ARCH=$(uname -m)
PROOT_VERSION="5.3.0"

# Map architecture
if [ "$ARCH" = "x86_64" ]; then
    ARCH_ALT=amd64
elif [ "$ARCH" = "aarch64" ]; then
    ARCH_ALT=arm64
else
    echo "Unsupported CPU architecture: ${ARCH}"
    exit 1
fi

# Download minimal rootfs tarball
if [ ! -e $ROOTFS_DIR/.installed ]; then
    mkdir -p $ROOTFS_DIR

    if [ "$DISTRO" = "debian" ]; then
        ROOTFS_URL="https://deb.debian.org/debian/dists/${RELEASE}/main/installer-${ARCH_ALT}/current/images/netboot/netboot.tar.gz"
    else
        ROOTFS_URL="https://cloud-images.ubuntu.com/minimal/releases/22.04/release/ubuntu-22.04-minimal-cloudimg-${ARCH_ALT}-root.tar.gz"
    fi

    echo "Downloading minimal ${DISTRO} rootfs..."
    curl -L $ROOTFS_URL -o /tmp/rootfs.tar.gz
    echo "Extracting..."
    tar -xzf /tmp/rootfs.tar.gz -C $ROOTFS_DIR
fi

# Download PRoot and GoTTY
if [ ! -e $ROOTFS_DIR/usr/local/bin/proot ]; then
    echo "Downloading PRoot..."
    curl -Lo $ROOTFS_DIR/usr/local/bin/proot \
         "https://github.com/proot-me/proot/releases/download/v${PROOT_VERSION}/proot-v${PROOT_VERSION}-${ARCH}-static"
    chmod 755 $ROOTFS_DIR/usr/local/bin/proot

    echo "Downloading GoTTY..."
    curl -Lo /tmp/gotty.tar.gz \
         "https://github.com/sorenisanerd/gotty/releases/download/v1.5.0/gotty_v1.5.0_linux_${ARCH_ALT}.tar.gz"
    tar -xzf /tmp/gotty.tar.gz -C $ROOTFS_DIR/usr/local/bin
    chmod 755 $ROOTFS_DIR/usr/local/bin/gotty
fi

# Setup DNS resolver
if [ ! -e $ROOTFS_DIR/.installed ]; then
    printf "nameserver 1.1.1.1\nnameserver 1.0.0.1" > $ROOTFS_DIR/etc/resolv.conf
    touch $ROOTFS_DIR/.installed
    rm -rf /tmp/rootfs.tar.gz /tmp/gotty.tar.gz
fi

# Welcome banner
clear && cat << EOF
 ██████╗ ███████╗ ██████╗ ██████╗ 
██╔═══██╗██╔════╝██╔═══██╗██╔══██╗
██║   ██║█████╗  ██║   ██║██████╔╝
██║   ██║██╔══╝  ██║   ██║██╔═══╝ 
╚██████╔╝███████╗╚██████╔╝██║     
 ╚═════╝ ╚══════╝ ╚═════╝ ╚═╝     
Welcome to ${DISTRO} Lite rootfs!
EOF

# Enter PRoot environment
$ROOTFS_DIR/usr/local/bin/proot \
    --rootfs="${ROOTFS_DIR}" \
    --link2symlink \
    --kill-on-exit \
    --root-id \
    --cwd=/root \
    --bind=/proc \
    --bind=/dev \
    --bind=/sys \
    --bind=/tmp \
    /bin/bash
