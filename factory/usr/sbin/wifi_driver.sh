#! /bin/sh
### BEGIN INIT INFO
# File:				rtl8188ftv.sh(wifi_driver.sh)	
# Provides:         8188 driver install and uninstall
# Required-Start:   $
# Required-Stop:
# Default-Start:     
# Default-Stop:
# Short-Description:install driver
# Author:			
# Email: 			
# Date:				2017-08-07
### END INIT INFO

PATH=$PATH:/bin:/sbin:/usr/bin:/usr/sbin
MODE=$1

wifi_ctl_level=`cat /etc/jffs2/anyka_cfg.ini | grep -e ctl_level | awk -F ' ' '{printf $3}'`

if [ $wifi_ctl_level == 0 ];then
	poweron=0
	poweroff=1
else
	poweron=1
	poweroff=0
fi

usage()
{
	echo "Usage: $0 station | smartlink | ap | uninstall"
}

station_uninstall()
{
	#rm usb wifi driver(default)
	ID=`lsusb | awk '{print $6}'|grep 8888`
	if [ -n "$ID" ];then # 6032i wifi
		rmmod atbm603x_wifi_usb
	else
		rmmod 8188fu
	fi
	rmmod otg-hs
	
	echo $poweroff > /sys/user-gpio/wifi_power  #power off
}

station_install()
{
 #install usb wifi driver(default)
	sleep 1
	echo $poweron >/sys/user-gpio/wifi_power #南方硅谷wifi设置1供电，0断电
    sleep 1 #### 等待电源稳定后再加载其他驱动	
	insmod /usr/modules/otg-hs.ko
	sleep 2 #### 等待otg 向usb host 核心层完成一些注册工作后再加在驱动
	
	ID=`lsusb | awk '{print $6}'|grep 8888`
	if [ -n "$ID" ];then #南方硅谷wifi
		insmod /usr/modules/atbm603x_wifi_usb.ko
	else
		insmod /usr/modules/rtl8188fu.ko
	fi

}

smartlink_uninstall()
{
	#rm usb wifi driver(default)
	ID=`lsusb | awk '{print $6}'|grep 8888`
	if [ -n "$ID" ];then #南方硅谷wifi
		rmmod atbm603x_wifi_usb
	else
		rmmod 8188fu
	fi
	rmmod otg-hs
	
	echo $poweroff > /sys/user-gpio/wifi_power  #power off
}

smartlink_install()
{
 #install usb wifi driver(default)
	echo $poweron >/sys/user-gpio/wifi_power #南方硅谷wifi设置1供电，0断电
    sleep 1 #### 等待电源稳定后再加载其他驱动	
	insmod /usr/modules/otg-hs.ko
	sleep 2 #### 等待otg 向usb host 核心层完成一些注册工作后再加在驱动
	
	ID=`lsusb | awk '{print $6}'|grep 8888`
	if [ -n "$ID" ];then #南方硅谷wifi
		insmod /usr/modules/atbm603x_wifi_usb.ko
	else
		insmod /usr/modules/rtl8188fu.ko
	fi

}

ap_install()
{
 #install usb wifi driver(default)
	echo $poweron >/sys/user-gpio/wifi_power #南方硅谷wifi设置1供电，0断电
    sleep 1 #### 等待电源稳定后再加载其他驱动	
	insmod /usr/modules/otg-hs.ko
	sleep 2 #### 等待otg 向usb host 核心层完成一些注册工作后再加在驱动
	
	ID=`lsusb | awk '{print $6}'|grep 8888`
	if [ -n "$ID" ];then #南方硅谷wifi
		insmod /usr/modules/atbm603x_wifi_usb.ko
	else
		insmod /usr/modules/rtl8188fu.ko
	fi

}

ap_uninstall()
{
	#rm usb wifi driver(default)
	ID=`lsusb | awk '{print $6}'|grep 8888`
	if [ -n "$ID" ];then #南方硅谷wifi
		rmmod atbm603x_wifi_usb
	else
		rmmod 8188fu
	fi
	rmmod otg-hs
	
	echo $poweroff > /sys/user-gpio/wifi_power  #power off
}

wlan0_up(){
	ID=`ifconfig | grep wlan0 | awk '{print $1}' `
	if [ -z $ID ] ;then
		if [ -d /sys/class/net/wlan0/ ] ;then
                	echo "ifconfig wlan0 up"
                	ifconfig wlan0 up
			iwpriv wlan0 fwcmd cfo,1
        	else
                	echo "can't found /sys/class/net/wlan0/"
        	fi
	else
		iwpriv wlan0 fwcmd cfo,1
		echo "iwpriv wlan0 fwcmd cfo,1"
	fi
}

####### main

case "$MODE" in
	station)
		station_install
		wlan0_up
		;;
	smartlink)
		smartlink_install
		wlan0_up
		iwconfig wlan0 mode monitor
		;;	
	ap)
		ap_install
		wlan0_up
		;;
	uninstall)
		station_uninstall
		smartlink_uninstall
		ap_uninstall
		;;
	*)
		usage
		;;
esac
exit 0


