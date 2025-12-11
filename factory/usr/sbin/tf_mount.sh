#!/bin/sh

mount -t vfat /dev/mmcblk0p1 /mnt 2> /dev/null
if [ $? -ne 0 ]; then
  mount -t vfat /dev/mmcblk0 /mnt 2> /dev/null
  if [ $? -ne 0 ]; then
	mount /dev/mmcblk0p1 /mnt/
	if [ $? -ne 0 ]; then
		mount /dev/mmcblk0 /mnt/
	fi
  fi
fi
exit $?
