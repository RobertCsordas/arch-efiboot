#!/bin/bash -e

TARGET=/boot
BOOTDIR=/boot
UCODE=$BOOTDIR/intel-ucode.img
EFISTUB=/usr/lib/systemd/boot/efi/linuxx64.efi.stub

if [[ $# -gt 0 ]]; then
	KERNEL_IMAGES=()
	for KERNEL in "$@"; do
		KERNEL_IMAGE="${BOOTDIR}/vmlinuz-${KERNEL}"

		if [ ! -f "${KERNEL_IMAGE}" ]; then
			echo "Kernel \"${KERNEL}\" not available."

			exit 1;
		fi

		KERNEL_IMAGES+=("${KERNEL_IMAGE}")
	done
else
	KERNEL_IMAGES=($BOOTDIR/vmlinuz*)
fi

for k in "${KERNEL_IMAGES[@]}"; do
	NAME=$(basename $k|sed 's/vmlinuz-//')
	echo "Updating EFI kernel $NAME..."
	INITRD="$BOOTDIR/initramfs-$NAME.img"

	if [ -f "$UCODE" ]; then
		cat "$UCODE" "$INITRD" > /tmp/initrd.bin
		INITRDFILE=/tmp/initrd.bin
	else
		# Do not fail on AMD systems
		echo "  Intel microcode not found. Skipping."
		INITRDFILE="$INITRD"
	fi

	# Check for custom command line for the kernel.
	CMDLINE="$BOOTDIR/cmdline-$NAME.txt"
	if [ -f "$CMDLINE" ]; then
		echo "  Using custom command line $CMDLINE"
	else
		CMDLINE="$BOOTDIR/cmdline.txt"
		if [ ! -f "$CMDLINE" ]; then
			echo "  CMDLINE missing. Extracting from running kernel..."
			cat /proc/cmdline |sed 's/BOOT_IMAGE=[^ ]* \?//' > "$CMDLINE"
		fi
	fi

	objcopy \
	    --add-section .osrel="/usr/lib/os-release" --change-section-vma .osrel=0x20000 \
	    --add-section .cmdline="$CMDLINE" --change-section-vma .cmdline=0x30000 \
	    --add-section .linux="$k" --change-section-vma .linux=0x40000 \
	    --add-section .initrd="$INITRDFILE" --change-section-vma .initrd=0x3000000 \
	    "$EFISTUB" "$TARGET/$NAME.efi"
done
