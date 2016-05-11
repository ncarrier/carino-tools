#!/bin/bash

# create a sparse file for storing servos setpoints
iomem_size=8M
iomem_file=servos-uml.iomem
truncate -s ${iomem_size} ${iomem_file}

out/carino-obstination_pc/build/linux/linux \
		umid=obstination_pc \
		root=/dev/root \
		rootflags=$PWD/out/carino-obstination_pc/final \
		eth0=tuntap,,,10.10.10.254 \
		rootfstype=hostfs \
		iomem=servos-uml,${iomem_file}
