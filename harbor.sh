#!/bin/sh

#############################
# Ubuntu Lite Install        #
#############################

ROOTFS_DIR=/home/container
ARCH=$(uname -m)
PROOT_VERSION="5.3.0"
UBUNTU_URL="https://github.com/EXALAB/Anlinux-Resources/raw/refs/heads/master/Rootfs/Ubuntu/amd64/ubuntu-rootfs-amd64.tar.xz"

# Only support x86_64
if [ "$ARCH" != "x86_64" ]; then
    echo "Unsupported CPU architecture: ${ARCH}"
    exit 1
fi

# Download and extract Ubuntu rootfs
if [ ! -e $ROOTFS_DIR/.installed ]; then
    mkdir -p $ROOTFS_DIR
    echo "Downloading Ubuntu rootfs..."
    curl -L $UBUNTU_URL -o /tmp/ubuntu-rootfs.tar.xz
    echo "Extracting rootfs..."
    # --strip-components=1 ensures the contents go directly into ROOTFS_DIR
    tar -xJf /tmp/ubuntu-rootfs.tar.xz -C $ROOTFS_DIR --strip-components=1
fi

# Download PRoot
if [ ! -e $ROOTFS_DIR/usr/local/bin/proot ]; then
    echo "Downloading PRoot..."
    mkdir -p $ROOTFS_DIR/usr/local/bin
    curl -Lo $ROOTFS_DIR/usr/local/bin/proot \
         "https://github.com/proot-me/proot/releases/download/v${PROOT_VERSION}/proot-v${PROOT_VERSION}-${ARCH}-static"
    chmod 755 $ROOTFS_DIR/usr/local/bin/proot
fi

# Download GoTTY
if [ ! -e $ROOTFS_DIR/usr/local/bin/gotty ]; then
    echo "Downloading GoTTY..."
    curl -Lo /tmp/gotty.tar.gz \
         "https://github.com/sorenisanerd/gotty/releases/download/v1.5.0/gotty_v1.5.0_linux_amd64.tar.gz"
    tar -xzf /tmp/gotty.tar.gz -C $ROOTFS_DIR/usr/local/bin
    chmod 755 $ROOTFS_DIR/usr/local/bin/gotty
fi

# Setup DNS resolver
if [ ! -e $ROOTFS_DIR/.installed ]; then
    printf "nameserver 1.1.1.1\nnameserver 1.0.0.1" > $ROOTFS_DIR/etc/resolv.conf
    touch $ROOTFS_DIR/.installed
    rm -rf /tmp/ubuntu-rootfs.tar.xz /tmp/gotty.tar.gz
fi

# Welcome banner
clear && cat << EOF
 ██████╗ ██╗   ██╗██████╗ ███████╗
██╔═══██╗██║   ██║██╔══██╗██╔════╝
██║   ██║██║   ██║██████╔╝█████╗  
██║   ██║██║   ██║██╔═══╝ ██╔══╝  
╚██████╔╝╚██████╔╝██║     ███████╗
 ╚═════╝  ╚═════╝ ╚═╝     ╚══════╝
Welcome to Ubuntu Lite rootfs!
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
