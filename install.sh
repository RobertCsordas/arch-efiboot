#!/bin/bash

if [ "$(mount|grep '/boot '|grep vfat)" == "" ]; then
	echo "Your /boot is not a fat32 filesystem, so it might not be the EFI mount point. Please read the readme.md and continue setup manually."
	exit 1
fi

if [ "$(id -u)" -ne 0 ]; then
	echo "Please run as root."
	exit 1
fi

cp build_efi_kernels.sh /opt/
mkdir -p /etc/pacman.d/hooks
cp hooks/* /etc/pacman.d/hooks/

echo "Install completed. Building kernels..."

/opt/build_kernel.sh

echo "Done"
