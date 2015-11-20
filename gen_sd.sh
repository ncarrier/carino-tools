#!/bin/bash

# generates a bootable sdcard image with the kernel and rootfs

# requires that the executables dcfldd, losetup, fdisk, kpartx, mkfs.vfat and
# mkfs.ext4 are present in the path

#set -x
set -e

# TODO factor this with the global config
# TODO should this, be done in a host alchemy module ?
# TODO or as a new, custom, image type ?
OUT_DIR=./out/carino-obstination
IMAGE_SIZE=80
BOOT_DIR=${OUT_DIR}/staging/boot
FINAL_DIR=${OUT_DIR}/final
U_BOOT_DIR=${BOOT_DIR}
BOOT_PARTITION_SIZE=10
CONFIG_DIR=products/carino/obstination/config

if [ "$(id -u)" != 0 ]; then
	echo this script must be ran as root user
	exit 1
fi

img_file=${OUT_DIR}/carino.img

dcfldd if=/dev/zero of=${img_file} bs=1M count=${IMAGE_SIZE}

loop_dev=$(losetup -f --show ${img_file})

# the fdisk command fail when reloading partitions
set +e
# dont remove blank lines, they are meaningful, they interact with fdisk's prompt
fdisk ${loop_dev} <<EOF
n
p
1

+${BOOT_PARTITION_SIZE}M
n
p
2


w
EOF
set -e

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
cp ${BOOT_DIR}/uImage ${mount_point}
cp ${CONFIG_DIR}/uEnv.txt ${mount_point}
cp ${OUT_DIR}/build/linux/arch/arm/boot/dts/sun7i-a20-pcduino3-nano.dtb ${mount_point}
sync
umount ${mount_point}

mount /dev/mapper/${root_partition} ${mount_point}
cp -rf --preserve=mode,timestamps ${FINAL_DIR}/* ${mount_point}
# alchemy forcefully copies the zImage, which we don't need
rm ${mount_point}/boot/zImage
sync
umount ${mount_point}

# unmount / cleanup
rm -r ${mount_point}
sync
kpartx -d ${loop_dev}
losetup -d ${loop_dev}

echo SD image created at ${img_file}
