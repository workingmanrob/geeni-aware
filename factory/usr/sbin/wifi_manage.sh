#! /bin/sh
### BEGIN INIT INFO
# File:				wifi_manage.sh	
# Provides:         manage wifi AP station and smartlink
# Required-Start:   $
# Required-Stop:
# Default-Start:     
# Default-Stop:
# Short-Description:start wifi run at ap  station or smartlink
# Author:			
# Email: 			
# Date:				2012-8-8
### END INIT INFO

PATH=$PATH:/bin:/sbin:/usr/bin:/usr/sbin
MODE=$1
cfgfile="/etc/jffs2/anyka_cfg.ini"
tmp_wifi_cfgfile="/tmp/wifi_info"
tmp_wifi_gbk_ssid="/tmp/wireless/gbk_ssid"
tmp_wifi_utf8_ssid="/tmp/wireless/utf8_ssid"
tmp_wifi_dir="/tmp/wireless"

TEST_MODE=0

usage()
{
	echo "$0 start_ap | stop_ap | start_sta | stop_sta | start_concurrent | stop_concurrent | stop"
}

play_please_config_net()
{
#	echo "play please config wifi tone"
#	ccli misc --tips "/usr/share/anyka_please_config_net.mp3"
	#/usr/sbin/blue_led.sh off
	#/usr/sbin/red_led.sh blink 250 250
}

play_get_config_info()
{
	echo "play get wifi config tone"
#	ccli misc --tips "/usr/share/anyka_camera_get_config.mp3"	
#	tuya dingding voice
	ccli misc --tips "/usr/share/tuya_sound2.mp3"	
	#/usr/sbin/blue_led.sh blink 250 250
}

play_afresh_net_config()
{
#	echo "play please afresh config net tone"
#	ccli misc --tips "/usr/share/anyka_afresh_net_config.mp3"
#	/usr/sbin/blue_led.sh off
#	/usr/sbin/red_led.sh blink 250 250
}

using_static_ip()
{
	ipaddress=`awk 'BEGIN {FS="="}/\[ethernet\]/{a=1} a==1&&$1~/^ipaddr/{gsub(/\"/,"",$2);gsub(/\;.*/, "", $2);gsub(/^[[:blank:]]*/,"",$2);print $2}' $cfgfile`
	
	netmask=`awk 'BEGIN {FS="="}/\[ethernet\]/{a=1} a==1&&$1~/^netmask/{gsub(/\"/,"",$2);gsub(/\;.*/, "", $2);gsub(/^[[:blank:]]*/,"",$2);print $2}' $cfgfile`
	gateway=`awk 'BEGIN {FS="="}/\[ethernet\]/{a=1} a==1&&$1~/^gateway/{gsub(/\"/,"",$2);gsub(/\;.*/, "", $2);gsub(/^[[:blank:]]*/,"",$2);print $2}' $cfgfile`

	ifconfig wlan0 $ipaddress netmask $netmask
	route add default gw $gateway
	sleep 1
}

driver_install()
{
	echo "install wifi driver"
	## install station driver
	/usr/sbin/wifi_driver.sh install
	i=0
	###### wait until the wifi driver insmod finished.
	while [ $i -lt 3 ]
	do
		if [ -d "/sys/class/net/wlan0" ];then
			ifconfig wlan0 up
			break
		else
			sleep 1
			i=`expr $i + 1`
		fi
	done
	
	if [ $i -eq 3 ];then
		echo "wifi driver install error, exit"
		return 1
	fi

	echo "wifi driver install OK"
	return 0
}

driver_uninstall()
{
	/usr/sbin/wifi_driver.sh uninstall
}

ap_start()
{
	echo "start ap"
	/usr/sbin/wifi_ap.sh start
}

ap_stop()
{

	echo "stop ap"
	/usr/sbin/wifi_ap.sh stop
}

station_start()
{
	/usr/sbin/wifi_station.sh start
	
	pid=`pgrep wpa_supplicant`
	if [ -z "$pid" ];then
		echo "the wpa_supplicant init failed, exit start wifi"
		return 1
	else
		return 0
	fi


}

station_stop()
{
	/usr/sbin/wifi_station.sh stop
}

station_connect()
{
	/usr/sbin/wifi_station.sh connect
	ret=$?
	echo "wifi connect return val: $ret"
	if [ $ret -eq 0 ];then
		echo "wifi connected!"
		return 0
	else
		echo "[station start] wifi station connect failed"
	fi

	return $ret
}

station_start_and_connect()
{
	#blue led on
#	/usr/sbin/red_led.sh off
#	/usr/sbin/blue_led.sh blink 250 250
	station_start
	station_connect
}

smartlink_driver_install()
{
	echo "start smartlink"
	/usr/sbin/wifi_driver.sh uninstall
	/usr/sbin/wifi_driver.sh smartlink
}

auto_start()
{
	ssid=`awk 'BEGIN {FS="="}/\[wireless\]/{a=1} a==1 && $1~/^ssid/{gsub(/\"/,"",$2);
		gsub(/\;.*/, "", $2);gsub(/^[[:blank:]]*/,"",$2);print $2}' $cfgfile`

	if [ "$ssid" = "" ];then
		#start smartlink mode
		iwconfig wlan0 mode Monitor
		while true
		do
			ipc_pid=`pgrep anyka_ipc`
			if [ "$ipc_pid" != "" ];then
				echo "anyka_ipc is running"
				break
			fi
			sleep 1
		done
		#play_please_config_net

		while true
		do
			##check gbk ssid
			if [ -e $tmp_wifi_gbk_ssid ];then		
				#play_get_config_info
				station_start_and_connect
				if [ "$?" = 0 ];then
					### rm tmp file and break
					rm -rf $tmp_wifi_dir
					rm -f $tmp_wifi_cfgfile
					break
				else
					echo "connect failed, ret: $?, please check your ssid and password !!!"
					play_afresh_net_config
					#### clean config file and re-config
					/usr/sbin/wifi_station.sh stop
					rm -rf $tmp_wifi_dir
					rm -f $tmp_wifi_cfgfile
				fi
			fi
			sleep 1
		done
	else
		station_start_and_connect
	fi
}

#main
if test -e /etc/jffs2/danale.conf ;then
	TEST_MODE=0
else
	TEST_MODE=1
fi

case "$MODE" in
	start_ap)
		driver_install
		ap_start
		;;
	stop_ap)
		ap_stop
		driver_uninstall
		;;
	start_sta)
		driver_install
		auto_start
		;;
	stop_sta)
		station_stop
		driver_uninstall
		;;
	start_concurrent)
		driver_install
		auto_start
		ap_start
		;;
	stop_concurrent)
		station_stop
		ap_stop
		driver_uninstall
		;;
	stop)
		station_stop
		ap_stop
		driver_uninstall
		;;
	*)
		usage
		;;
esac

