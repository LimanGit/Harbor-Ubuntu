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
    /bin/bash    tar -xzf /tmp/rootfs.tar.gz -C $ROOTFS_DIR
fi

################################
# Package Installation & Setup #
################################

# Download static APK-Tools temporarily because minirootfs does not come with APK pre-installed.
if [ ! -e $ROOTFS_DIR/.installed ]; then
    # Download the packages from their sources.
    curl -Lo /tmp/apk-tools-static.apk "https://dl-cdn.alpinelinux.org/alpine/v${ALPINE_VERSION}/main/${ARCH}/apk-tools-static-${APK_TOOLS_VERSION}.apk"
    curl -Lo /tmp/gotty.tar.gz "https://github.com/sorenisanerd/gotty/releases/download/v1.5.0/gotty_v1.5.0_linux_${ARCH_ALT}.tar.gz"
    curl -Lo $ROOTFS_DIR/usr/local/bin/proot "https://github.com/proot-me/proot/releases/download/v${PROOT_VERSION}/proot-v${PROOT_VERSION}-${ARCH}-static"
    # Extract everything that needs to be extracted.
    tar -xzf /tmp/apk-tools-static.apk -C /tmp/
    tar -xzf /tmp/gotty.tar.gz -C $ROOTFS_DIR/usr/local/bin
    # Install base system packages using the static APK-Tools.
    /tmp/sbin/apk.static -X "https://dl-cdn.alpinelinux.org/alpine/v${ALPINE_VERSION}/main/" -U --allow-untrusted --root $ROOTFS_DIR add alpine-base apk-tools
    # Make PRoot and GoTTY executable.
    chmod 755 $ROOTFS_DIR/usr/local/bin/proot $ROOTFS_DIR/usr/local/bin/gotty
fi

# Clean-up after installation complete & finish up.
if [ ! -e $ROOTFS_DIR/.installed ]; then
    # Add DNS Resolver nameservers to resolv.conf.
    printf "nameserver 1.1.1.1\nnameserver 1.0.0.1" > ${ROOTFS_DIR}/etc/resolv.conf
    # Wipe the files we downloaded into /tmp previously.
    rm -rf /tmp/apk-tools-static.apk /tmp/rootfs.tar.gz /tmp/sbin
    # Create .installed to later check whether Alpine is installed.
    touch $ROOTFS_DIR/.installed
fi

# Print some useful information to the terminal before entering PRoot.
# This is to introduce the user with the various Alpine Linux commands.
clear && cat << EOF

 ██╗  ██╗ █████╗ ██████╗ ██████╗  ██████╗ ██████╗ 
 ██║  ██║██╔══██╗██╔══██╗██╔══██╗██╔═══██╗██╔══██╗
 ███████║███████║██████╔╝██████╔╝██║   ██║██████╔╝
 ██╔══██║██╔══██║██╔══██╗██╔══██╗██║   ██║██╔══██╗
 ██║  ██║██║  ██║██║  ██║██████╔╝╚██████╔╝██║  ██║
 ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚═════╝  ╚═════╝ ╚═╝  ╚═╝
 
 Welcome to Alpine Linux minirootfs!
 This is a lightweight and security-oriented Linux distribution that is perfect for running high-performance applications.
 
 Here are some useful commands to get you started:
 
    apk add [package] : install a package
    apk del [package] : remove a package
    apk update : update the package index
    apk upgrade : upgrade installed packages
    apk search [keyword] : search for a package
    apk info [package] : show information about a package
    gotty -p [server-port] -w ash : share your terminal
 
 If you run into any issues make sure to report them on GitHub!
 https://github.com/RealTriassic/Harbor
 
EOF

###########################
# Start PRoot environment #
###########################

# This command starts PRoot and binds several important directories
# from the host file system to our special root file system.
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
/bin/sh
