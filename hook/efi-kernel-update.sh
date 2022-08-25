#!/bin/bash -e

while read -r updated_file; do
	if [[ $updated_file == usr/lib/initcpio/* ]]; then
		# all kernels images have been updated
		build_efi_kernels

		break
	fi

	pkgbase_file="${updated_file%/vmlinuz}/pkgbase"
	if ! read -r kernel > /dev/null 2>&1 < "${pkgbase_file}"; then
		continue
	fi

	build_efi_kernels "${kernel}"
done
