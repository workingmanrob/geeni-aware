#!/bin/sh

umount -l /mnt 2> /dev/null

if [ $? -ne 0 ]; then
	umount -l /mnt/
fi

exit $?
