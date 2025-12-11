#! /bin/sh
### BEGIN INIT INFO
# File:				service.sh
# Provides:         init service
# Required-Start:   $
# Required-Stop:
# Default-Start:
# Default-Stop:
# Short-Description:web service
# Author:			gao_wangsheng
# Email: 			gao_wangsheng@anyka.oa
# Date:				2012-12-27
### END INIT INFO

MODE=$1
TEST_MODE=0
WIFI_TEST=0
FACTORY_TEST=0
AGING_TEST=0
PATH=$PATH:/bin:/sbin:/usr/bin:/usr/sbin

usage()
{
	echo "Usage: $0 start|stop)"
	exit 3
}

stop_service()
{
	killall -12 daemon
	echo "watch dog closed"
	sleep 5
	killall daemon
	killall cmd_serverd

	/usr/sbin/anyka_ipc.sh stop

	echo "stop network service......"
	killall net_manage.sh

    /usr/sbin/eth_manage.sh stop
    /usr/sbin/wifi_manage.sh stop
}

start_anykaipc()
{
	daemon
	/usr/sbin/blue_led.sh on
	
	if [ -f /tmp/save_log.txt ]; then
		echo "/mnt/save_log.txt file is exist, save log to file!"
		
		sh /usr/sbin/tf_mount.sh
		
		date '+%Y-%m-%d %H:%M:%S'>>/tmp/anyka_ipc.log 2>&1 &
		/usr/sbin/ipc_log_check.sh 2>&1 &
		/usr/bin/anyka_ipc>>/tmp/anyka_ipc.log 2>&1
	else
		/usr/sbin/anyka_ipc.sh start 
	fi
	
	

}

start_service ()
{
	cmd_serverd
	if [ $WIFI_TEST = 1 ]; then
	    #insmod /usr/modules/sdio_wifi.ko
	    insmod /usr/modules/8189fs.ko
	    /mnt/wifitest/wifi_test.sh 
	    echo "start wifi test."
	elif [ $FACTORY_TEST = 1 ]; then

		#echo 0 > /sys/class/leds/red_led/brightness
		#echo 1 > /sys/class/leds/blue_led/brightness
		
		/bin/tcpsvd 0 21 ftpd -w / -t 600 &
	    #product_test & 
	    #insmod /tmp/usbnet/otg-hs.ko
	    #insmod /tmp/usbnet/usbnet.ko
	    #insmod /tmp/usbnet/asix.ko
	    #insmod /tmp/usbnet/udc.ko
	    #insmod /tmp/usbnet/g_ether.ko
	    #sleep 1
	    #ifconfig eth0 up
	    #sleep 1
	    
	    sh /usr/sbin/tf_mount.sh
		  /tmp/myupdate.sh
	    #/usr/sbin/eth_manage.sh start
		start_anykaipc
	    echo "start anyka ipc."

    elif [ $AGING_TEST = 1 ]; then
	    #insmod /usr/modules/sdio_wifi.ko
	    insmod /usr/modules/8189fs.ko
	    sleep 1
	    ifconfig wlan0 up
	    sleep 1
	    /tmp/aging_test 
	    echo "start aging test."
	else
#		daemon
#		/usr/sbin/red_led.sh on
#		/usr/sbin/anyka_ipc.sh start 
		start_anykaipc
		echo "start net service......"
	fi

#	boot_from=`cat /proc/cmdline | grep nfsroot`
#	if [ -z "$boot_from" ] && [ $FACTORY_TEST = 0 ] && [ $WIFI_TEST = 0 ] && [ $AGING_TEST = 0 ];then
#		echo "start net service......"
#		/usr/sbin/net_manage.sh &
#	else
#		echo "## start from nfsroot, do not change ipaddress!"
#	fi
#	unset boot_from
}

restart_service ()
{
	echo "restart service......"
	stop_service
	start_service
}


# FIXME 这块需要优化，逻辑避免碎片化。
# 临时先挂载一下 TF 卡先。
# VVVVVVVVVVVVVVVV
sh /usr/sbin/tf_mount.sh







/usr/bin/update &

i=5
while [ $i -gt 0 ]
do
	sleep 1

	pid=`pgrep /usr/bin/update`
	if [ -z "$pid" ];then
		echo "The /usr/bin/update has exited !!!"
		break
	fi

	i=`expr $i - 1`
done


if test -f /tmp/net.sh ;then
    /tmp/net.sh
fi

FACTORY_TEST=0

uart=`cat /etc/jffs2/anyka_cfg.ini | grep -e debug_uart | awk -F ' ' '{printf $3}'`

if [[ $uart -eq 1 ]] || [[ -f /tmp/save_log.txt ]];then
	#start ftp server, dir=root r/w, -t 600s(timeout)
	/usr/bin/tcpsvd 0 21 ftpd -w / -t 600 &

	#echo "start telnet......"
	/usr/sbin/telnetd &
	#
	#open uart debug......
    devmem 0x08000074  32  0x0200030c
else
    devmem 0x08000074  32  0x02000300
fi



sh /usr/sbin/tf_umount.sh
# AAAAAAAAAAAAAAAA
# 临时先挂载一下 TF 卡先。


# 检测无线网卡，进入临时 AP 测试模式。
if test -f /tmp/setup.sh ;then
    /tmp/setup.sh
    exit
fi

# FIXME V300 PDK 跑起来需要这个配置文件
cp -a /usr/local/venc.cfg /etc/jffs2

# 从 TF 卡中升级
sh /usr/sbin/tf_update.sh
# 从 TF 卡中加载涂鸦 UUID
sh /usr/sbin/tf_tuya_uuid.sh
# 初始化以太网各个驱动。
#sh /usr/sbin/ethernet.sh
#sh /usr/sbin/wifi_driver.sh station
/usr/sbin/wifi_driver.sh station &

case "$MODE" in
	start)
		start_service
		;;
	stop)
		stop_service
		;;
	restart)
		restart_service
		;;
	*)
		usage
		;;
esac
exit 0

