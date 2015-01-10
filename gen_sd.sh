#!/bin/bash

# generates a bootable sdcard image with the kernel and rootfs

# requires that the executables dcfldd, losetup, fdisk, kpartx, mkfs.vfat and
# mkfs.ext4 are present in the path

set -x

. config/build_config

if [ "$(id -u)" != 0 ]; then
	echo this script must be ran as root user
	exit 1
fi

img_file=${OUT_DIR}/carino.img

dcfldd if=/dev/zero of=${img_file} bs=1M count=100

loop_dev=$(losetup -f --show ${img_file})

# dont remove blank lines, they are meaningful, they interact with fdisk's prompt
fdisk ${loop_dev} <<EOF
n
p
1

+50M
n
p
2


w
EOF

# reload /dev files according to the new partitions
partitions_list=$(LANG=C kpartx -av ${loop_dev} | sed 's/add map //g' | sed 's/ (.*//g')
partitions=( $partitions_list )
boot_partition=${partitions[0]}
root_partition=${partitions[1]}

# TODO without this small delay, partitions are reported as non existant, why ?
sleep 1

# format the partitions
mkfs.vfat /dev/mapper/${boot_partition}
mkfs.ext4 /dev/mapper/${root_partition}

# why this one ?
dcfldd if=/dev/zero of=${loop_dev} bs=1k count=1023 seek=1

# write u-boot
dcfldd if=${U_BOOT_DIR}/u-boot-sunxi-with-spl.bin of=${loop_dev} bs=1024 seek=8

# copy files
mount_point=$(mktemp --directory)
mount /dev/mapper/${boot_partition} ${mount_point}
cp ${BOOT_DIR}/* ${mount_point}
sync
umount ${mount_point}

mount /dev/mapper/${root_partition} ${mount_point}
cp -rpf ${FINAL_DIR}/* ${mount_point}
sync
umount ${mount_point}

# unmount / cleanup
rm -r ${mount_point}
sync
kpartx -d ${loop_dev}
losetup -d ${loop_dev}

echo SD image created at ${img_file}
