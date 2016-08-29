#!/bin/bash

check_permissions () {
    if [[ "$(id -u)" != 0 ]]; then
        echo "E: Requires root permissions" > /dev/stderr
        exit 1
    fi
}

check_dependencies () {
   PACKAGES="dctrl-tools dpkg-dev genisoimage gfxboot-theme-ubuntu isolinux live-build python-minimal squashfs-tools syslinux  syslinux-utils zsync"

for pkg in $PACKAGES; do
    
if dpkg --get-selections | grep -q "^$pkg[[:space:]]*install$" >/dev/null; then

        echo -e "$pkg is already installed"
    else
        apt-get install $pkg -y
        echo "Successfully installed $pkg"
    fi
done
}

copysyslinux () {
    BASE_DIR="$PWD"
    mkdir -p /usr/share/syslinux/themes/
    git clone https://github.com/budgie-remix/syslinux-themes-budgie-remix.git
    cd syslinux-themes-budgie-remix
    cp -R themes/budgie-remix /usr/share/syslinux/themes/
    cd $BASE_DIR 
}

removesyslinux () {
    rm -rf /usr/share/syslinux/themes/
    rm -rf cd $BASE_DIR/syslinux-themes-budgie-remix/
}


read_config () {
    BASE_DIR="$PWD"
    source "$BASE_DIR"/etc/terraform.conf
}

uefi () {
    ISO="$1"

    # /tmp/tmp.XXXXXXXXXX
    TMP_DIR=$(mktemp -d)

    clean_up () {
      umount "$TMP_DIR/mnt" >/dev/null 2>&1 || true
      rm -rf "$TMP_DIR"
    }
    trap clean_up EXIT

    # Create temporary directories
    mkdir -p "$TMP_DIR"/{contents,mnt}

    # Mount .iso
    mount -o loop,ro "$ISO" "$TMP_DIR/mnt"

    # Extract .iso contents
    cp -rT "$TMP_DIR/mnt" "$TMP_DIR/contents"

    # Unmount .iso so it can be overwritten
    umount "$TMP_DIR/mnt"

    # Perform magic
    xorriso -as mkisofs \
	-r \
	-J \
	-joliet-long \
	-A "$NAME $VERSION ${CODENAME^}" \
	-V "$NAME" \
	-volset "$NAME" \
	-partition_offset 16 \
	-isohybrid-mbr /usr/lib/ISOLINUX/isohdpfx.bin \
	-c isolinux/boot.cat \
	-b isolinux/isolinux.bin \
	-no-emul-boot \
	-boot-load-size 4 \
	-boot-info-table \
	-eltorito-alt-boot \
	-e boot/grub/efi.img \
	-no-emul-boot \
	-isohybrid-gpt-basdat \
	-o binary.hybrid.iso \
        "$TMP_DIR/contents"

    # CD and USB boot supportisohybrid --uefi "$ISO"
}

build () {
    BUILD_ARCH="$1"

    #  block size, compression, filter optimization
    export MKSQUASHFS_OPTIONS="-b 1024k -comp xz -Xbcj x86"

    mkdir -p "$BASE_DIR/tmp/$BUILD_ARCH"
    cd "$BASE_DIR/tmp/$BUILD_ARCH" || exit

    if [ ! -f ubuntu.iso ]; then
        wget "http://releases.ubuntu.com/$BASECODENAME/ubuntu-$BASEVERSION-desktop-$BUILD_ARCH.iso" --output-document ubuntu.iso \
        || wget "http://cdimage.ubuntu.com/daily-live/current/$BASECODENAME-desktop-$BUILD_ARCH.iso" --output-document ubuntu.iso
    fi

    # remove old configs and copy over new
    rm -rf config auto
    cp -r "$BASE_DIR"/etc/* .

    sed -i "s/all/$BUILD_ARCH/" terraform.conf
    sed -i "s/@SYSLINUX/$CODENAME/" auto/config

    lb clean
    lb config
    lb build

    if [ "$BUILD_ARCH" == "amd64" ]; then
        uefi binary.hybrid.iso
    fi

    md5sum binary.hybrid.iso > binary.hybrid.iso.md5.txt
    sha256sum binary.hybrid.iso > binary.hybrid.iso.sha256.txt

    YYYYMMDD="$(date +%Y%m%d)"
    mkdir -p "$BASE_DIR/builds/$YYYYMMDD/$BUILD_ARCH"
    mv binary.hybrid.iso "$BASE_DIR/builds/$YYYYMMDD/$BUILD_ARCH/budgie-remix-$VERSION-$BUILD_ARCH.$YYYYMMDD.iso"
    mv binary.* "$BASE_DIR/builds/$YYYYMMDD/$BUILD_ARCH/"
}

check_permissions
check_dependencies
copysyslinux
read_config

if [[ "$ARCH" == "all" ]]; then
    build amd64
    build i386
else
    build "$ARCH"
fi
removesyslinux


