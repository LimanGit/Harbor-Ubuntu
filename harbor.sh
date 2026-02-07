#!/bin/sh

#############################
# Ubuntu 22.04 Lite Install #
#############################

ROOTFS_DIR=/home/container
VAR_DIR=$ROOTFS_DIR/var
ARCH=$(uname -m)
PROOT_VERSION="5.3.0"
UBUNTU_URL="https://cloud-images.ubuntu.com/wsl/releases/22.04/current/ubuntu-jammy-wsl-amd64-wsl.rootfs.tar.gz"

# Only support x86_64
if [ "$ARCH" != "x86_64" ]; then
    echo "Unsupported CPU architecture: ${ARCH}"
    exit 1
fi

# Create necessary directories
mkdir -p $ROOTFS_DIR/usr/local/bin
mkdir -p $VAR_DIR
mkdir -p $ROOTFS_DIR/tmp
mkdir -p $ROOTFS_DIR/run
mkdir -p $ROOTFS_DIR/etc
mkdir -p $ROOTFS_DIR/root
mkdir -p $ROOTFS_DIR/home

# Download and extract Ubuntu rootfs if not installed
if [ ! -e $ROOTFS_DIR/.installed ]; then
    echo "Downloading Ubuntu rootfs..."
    curl -L $UBUNTU_URL -o $ROOTFS_DIR/ubuntu-rootfs.tar.gz
    echo "Extracting rootfs..."
    tar -xvzf $ROOTFS_DIR/ubuntu-rootfs.tar.gz -C $ROOTFS_DIR
    rm -f $ROOTFS_DIR/ubuntu-rootfs.tar.gz

    # Setup DNS resolver
    echo -e "nameserver 1.1.1.1\nnameserver 1.0.0.1" > $ROOTFS_DIR/etc/resolv.conf

    touch $ROOTFS_DIR/.installed
fi

# Download PRoot
if [ ! -e $ROOTFS_DIR/usr/local/bin/proot ]; then
    echo "Downloading PRoot..."
    curl -Lo $ROOTFS_DIR/usr/local/bin/proot \
         "https://github.com/proot-me/proot/releases/download/v${PROOT_VERSION}/proot-v${PROOT_VERSION}-${ARCH}-static"
    chmod 755 $ROOTFS_DIR/usr/local/bin/proot
fi

# Download GoTTY
if [ ! -e $ROOTFS_DIR/usr/local/bin/gotty ]; then
    echo "Downloading GoTTY..."
    curl -Lo $ROOTFS_DIR/usr/local/bin/gotty \
         "https://github.com/sorenisanerd/gotty/releases/download/v1.5.0/gotty_v1.5.0_linux_amd64"
    chmod 755 $ROOTFS_DIR/usr/local/bin/gotty
fi

# Welcome banner
clear && cat << EOF
 ██████╗ ██╗   ██╗██████╗ ███████╗
██╔═══██╗██║   ██║██╔══██╗██╔════╝
██║   ██║██║   ██║██████╔╝█████╗  
██║   ██║██║   ██║██╔═══╝ ██╔══╝  
╚██████╔╝╚██████╔╝██║     ███████╗
 ╚═════╝  ╚═════╝ ╚═╝     ╚══════╝
Welcome to Ubuntu 22.04 Lite rootfs!
EOF

# Enter PRoot environment with proper /var
$ROOTFS_DIR/usr/local/bin/proot \
    --rootfs="$ROOTFS_DIR" \
    --link2symlink \
    --kill-on-exit \
    --root-id \
    --cwd=/root \
    --bind=/proc \
    --bind=/dev \
    --bind=/sys \
    --bind=$VAR_DIR:/var \
    --bind=$ROOTFS_DIR/tmp:/tmp \
    --bind=$ROOTFS_DIR/run:/run \
    --bind=$ROOTFS_DIR/etc:/etc \
    --bind=$ROOTFS_DIR/root:/root \
    --bind=$ROOTFS_DIR/home:/home \
    /bin/bash
