#!/bin/sh

cfgfile="/etc/jffs2/anyka_cfg.ini"
#SSID=$2
#PWD=$3

wifi_ap_start()
{
	killall smartlink 2>/dev/null
	killall wpa_supplicant 2>/dev/null
	killall hostapd 2>/dev/null
	killall udhcpd 2>/dev/null
	ifconfig wlan0 down
	## check driver
	wifi_driver.sh uninstall
	wifi_driver.sh ap

	echo "start wlan0 on ap mode"
	ifconfig wlan0 up

#	ssid=$SSID
#	password=$PWD

#	echo "ap :: ssid=$ssid password=$password"
#	if [ -z "$ssid" ];then
#		ssid="123456"
#	fi

#	/usr/sbin/device_save.sh name "$ssid"
#	/usr/sbin/device_save.sh password "$password"

#	if [ -z $password ];then
#		/usr/sbin/device_save.sh setwpa 0
#	else
#		/usr/sbin/device_save.sh setwpa 2
#	fi

	ID=`lsusb | awk '{print $6}'|grep 8888`
	
	if [ -n "$ID" ];then #南方硅谷wifi
#		/usr/sbin/device_save_ssv6x5x.sh name "$ssid"
#		/usr/sbin/device_save_ssv6x5x.sh password "$password"
 
#		if [ -z $password ];then
#			/usr/sbin/device_save_ssv6x5x.sh setwpa 0
#		else
#			/usr/sbin/device_save_ssv6x5x.sh setwpa 2
#		fi
		hostapd_6032i /etc/jffs2/hostapd_6032i.conf -B
	else #rtl8188

		hostapd /etc/jffs2/hostapd.conf -B
	fi
	
	
		ifconfig wlan0 192.168.0.1
		#route del default 2>/dev/null
		#route add default gw 192.168.0.1 wlan0
		udhcpd /etc/jffs2/udhcpd.conf
	
}

wifi_ap_stop()
{
	killall hostapd 2>/dev/null
	killall udhcpd 2>/dev/null
	killall hostapd_ssv6x5x 2>/dev/null
	killall hostapd_6032i 2>/dev/null
	ifconfig wlan0 down
	wifi_driver.sh uninstall
    wifi_driver.sh install
    ifconfig wlan0 up
}

usage()
{
	echo "$0 start ssid password | stop"
}


case $1 in
	start)
		wifi_ap_start
		;;
	stop)
		wifi_ap_stop
		;;
	*)
		usage
		;;
esac
	


