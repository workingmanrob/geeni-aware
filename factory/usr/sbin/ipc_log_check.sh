#!/bin/sh

log_max_size=50  # 单位:K
log_file=/tmp/anyka_ipc.log
log_size=0

mount_status=0;
tf_card_log_file=/mnt/anyka_ipc.log

check_mount_status()
{
	if [ "`df -T -h | grep -i "dev/mmcblk0" | awk '{print $1}'`" == "" ]; then
	#	echo "tf card mount failed!"
		mount_status=0;
	else
	#	echo "tf card mount success!"
		mount_status=1;
	fi
}

copy_log_to_mnt()
{
	LINE=`wc -l $log_file|awk '{print $1}'`
	if [ $LINE -ne 1 ]; then
		check_mount_status
   		if [ $mount_status -eq 1 ];then
    		cat $log_file >>$tf_card_log_file 2>&1 &
    	fi  
		echo "$(date -R)" >$log_file
	fi
}

i=0
while true
do
	log_size=$(expr $(ls -l $log_file | awk '{print $5}') / 1024)
	if [ $log_size -ge $log_max_size ]; then
		i=0
		copy_log_to_mnt
	fi
	sleep 1
	i=`expr $i + 1`
	if [ $i -ge 30 ]; then
		i=0
		copy_log_to_mnt
	fi
done

