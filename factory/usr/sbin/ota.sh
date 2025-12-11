#!/bin/sh
# File:				update.sh	
# Provides:         
# Description:      update zImage&rootfs under dir1/dir2/...
# Author:			xc

VAR1="uImage"
VAR2="root.sqsh4"
VAR3="usr.sqsh4"
VAR4="usr.jffs2"

ZMD5="uImage.md5"
SMD5="usr.sqsh4.md5"
JMD5="usr.jffs2.md5"
RMD5="root.sqsh4.md5"

UPDATE_FLAG=0

DIR1="/tmp"
DIR2="/mnt"
UPDATE_DIR_TMP=0

update_voice_tip()
{
	echo "play update voice tips"
	ccli misc --tips "/usr/share/anyka_update_device.mp3"
	sleep 3
}

update_ispconfig()
{
	rm -rf /etc/jffs2/isp*.conf
}

update_kernel()
{
	echo "check ${VAR1}............................."

	if [ -e ${DIR1}/${VAR1} ] 
	then
		if [ -e ${DIR1}/${ZMD5} ];then

			result=`md5sum -c ${DIR1}/${ZMD5} | grep OK`
			if [ -z "$result" ];then
				echo "MD5 check zImage failed, can't updata"
				return
			else
				echo "MD5 check zImage success"
			fi
		fi

		echo "update ${VAR1} under ${DIR1}...."
		updater local F=${DIR1}/${VAR1}
		UPDATE_FLAG=$( expr $UPDATE_FLAG + 2)
	fi	
}

update_squash()
{		
	echo "check ${VAR3}.........................."

	if [ -e ${DIR1}/${VAR3} ]
	then
		if [ -e ${DIR1}/${SMD5} ];then

			result=`md5sum -c ${DIR1}/${SMD5} | grep OK`
			if [ -z "$result" ];then
				echo "MD5 check usr.sqsh4 failed, can't updata"
				return
			else
				echo "MD5 check usr.sqsh4 success"
			fi
		fi

		echo "update ${VAR3} under ${DIR1}...."
		updater local D=${DIR1}/${VAR3}
		UPDATE_FLAG=$( expr $UPDATE_FLAG + 1)
	fi	
}

update_rootfs_squash()
{		
	echo "check ${VAR2}.........................."

	if [ -e ${DIR1}/${VAR2} ]
	then
		if [ -e ${DIR1}/${RMD5} ];then

			result=`md5sum -c ${DIR1}/${RMD5} | grep OK`
			if [ -z "$result" ];then
				echo "MD5 check root.sqsh4 failed, can't updata"
				return
			else
				echo "MD5 check root.sqsh4 success"
			fi
		fi

		echo "update ${VAR2} under ${DIR1}...."
		updater local E=${DIR1}/${VAR2}	
		UPDATE_FLAG=$( expr $UPDATE_FLAG + 4)
	fi	
}

update_check_image()
{
	echo "check update image .........................."

	for target in ${VAR1} ${VAR2} ${VAR3} ${VAR4}
	do
		if [ -f ${DIR1}/${target} ]; then
			echo "find a target ${target}, update in /tmp"
			UPDATE_DIR_TMP=1
			break
		fi	
	done
}

#
# main:
#
echo ""
echo "### enter update.sh ###"
echo "stop system service before update....."
# play update vioce tip
update_voice_tip

# send signal to stop watchdog
# sleep to wait the program exit
echo "############ please wait a moment. And don't remove TFcard or power-off #############"

#led blink
/usr/sbin/led.sh blink 50 50

# cp busybox to tmp, avoid the command become no use
cp /bin/busybox /tmp/

update_check_image

if [ $UPDATE_DIR_TMP -ne 1 ];then
	## copy the image file to /tmp to avoid update fail on TF-card
	for dir in ${VAR1} ${VAR2} ${VAR3} ${VAR4}
	do
		cp ${DIR2}/${dir} /tmp/ 2>/dev/null
		cp ${DIR2}/${dir}.md5 /tmp/ 2>/dev/null
	done
	umount /mnt/ -l
	echo "update use image from /mnt"
else
	echo "update use image from /tmp"
fi
cd ${DIR1}

update_ispconfig

update_kernel
update_squash
update_rootfs_squash

/tmp/busybox echo "############ update finished, reboot now #############"

echo $UPDATE_FLAG

write_env   $UPDATE_FLAG

/tmp/busybox sleep 3
/tmp/busybox reboot -f
