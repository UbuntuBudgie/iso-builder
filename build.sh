#!/bin/bash

CONFIG_FILE="$1"

#source "$CONFIG_FILE"

echo -e "
#----------------------#
# INSTALL DEPENDENCIES #
#----------------------#
"

apt-get update
apt-get install -y live-build patch binutils zstd
apt-get install -y ./ubuntu-keyring_2020.06.17.1-1_all.deb
apt-get install -y ./debootstrap_1.0.124_all.deb

patch /usr/lib/live/build/binary_grub-efi < live-build-fix-shim-remove.patch

ln -sfn /usr/share/debootstrap/scripts/gutsy /usr/share/debootstrap/scripts/impish

echo -e "
#----------------------#
# RUN TERRAFORM SCRIPT #
#----------------------#
"

#./terraform.sh --config-path "$CONFIG_FILE"
#cp builds/amd64/* /artifacts/
./terraform.sh

