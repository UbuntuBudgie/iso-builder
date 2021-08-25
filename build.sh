#!/bin/bash

CONFIG_FILE="$1"

#source "$CONFIG_FILE"

echo -e "
#----------------------#
# INSTALL DEPENDENCIES #
#----------------------#
"

apt-get update
apt-get install -y live-build patch
apt-get install -y ./ubuntu-keyring_2020.02.11.4_all.deb

patch -d /usr/lib/live/build/ < live-build-fix-shim-remove.patch

echo -e "
#----------------------#
# RUN TERRAFORM SCRIPT #
#----------------------#
"

#./terraform.sh --config-path "$CONFIG_FILE"
#cp builds/amd64/* /artifacts/
./terraform.sh

