#!/bin/sh
# File:				update_check.sh	
# Provides:         
# Description:      update zImage&rootfs under /tmp...
# Author:			dongfeilong

VAR1="uImage"
VAR2="root.sqsh4"
VAR3="usr.sqsh4"
VAR4="usr.jffs2"

ZMD5="uImage.md5"
SMD5="usr.sqsh4.md5"
JMD5="usr.jffs2.md5"
RMD5="root.sqsh4.md5"

DIR1="/tmp"
UPDATE_DIR_TMP=0

UPDATE_FILE=/tmp/update.tar

# 参数 $1 表示 block 名称，见 /proc/mtd
# 参数 $2 表示要升级的镜像路径，如 /tmp/uImage
update_block()
{
  if [ -f $2 ]; then
    echo "Update $1 from $2."
    updater local $1=$2
  fi
}

# 解压升级包。
tar -xf ${UPDATE_FILE} -C /tmp/

# 根据涂鸦 V4.2.0 定义。
# 固件升级时，红率灯同时闪烁产生黄灯闪烁的效果。
/usr/sbin/blue_led.sh blink 100 100
#/usr/sbin/red_led.sh blink 1500 1500

cp /sbin/reboot /tmp
cp /bin/sleep /tmp

update_block "KERNEL" "/tmp/uImage"
update_block "B" "/tmp/usr.jffs2"
update_block "C" "/tmp/usr.sqsh4"
update_block "A" "/tmp/root.sqsh4"

echo "############ update finished, reboot now #############"

/tmp/sleep 3
/tmp/reboot -f
