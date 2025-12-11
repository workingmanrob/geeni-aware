#!/bin/sh

### BEGIN INIT INFO
# File:				check_wifi_state	
# Description:      check wifi state in station 
# Author:			li_zhenying
# Email: 			xiaoxiao@techvision.com.cn
# Date:				2016-01-21
### END INIT INFO
times_count=0
station_start()
{
	### remove all wifi driver
	/usr/sbin/wifi_driver.sh uninstall
	sed -i 's/^running.*/running = station/' $cfgfile
	sleep 7
	/usr/sbin/wifi_driver.sh station
	sleep 5
	if [ -d "/var/run/wpa_supplicant" ];then
       rm -rf /var/run/wpa_supplicant
	fi
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
	/usr/sbin/tuya_wifi_station.sh start
	
	pid=`pgrep wpa_supplicant`
	if [ -z "$pid" ];then
		echo "the wpa_supplicant init failed, exit start wifi"
		return 1
	fi

	/usr/sbin/tuya_wifi_station.sh connect
	ret=$?
	echo "wifi connect return val: $ret"
	if [ $ret -eq 0 ];then
		echo "wifi connected!"
		return 0
	else
		echo "[station start] wifi station connect failed"
		ifconfig wlan0 down
		/usr/sbin/wifi_station.sh stop
		killall -15 wifi_station.sh
	fi
    echo $ret
	return $ret
}

#status=`ifconfig wlan0 | grep RUNNING`
#LOCK_NAME="/tmp/my.lock"
#if ( set -o noclobber; echo "$$" > "$LOCK_NAME") 2> /dev/null; 
#then
#	trap 'rm -f "$LOCK_NAME"; exit $?' INT TERM EXIT
	while true
	do   
#	   check_ipc=`pgrep anyka_ipc`
#	   if [ "$check_ipc" != "" ];then
		   gateway=`ip route | grep "via" | grep default | cut -d' '  -f3`
			if [ -z "$gateway" ] ; then
				echo "wlan0 is not exist......"
				echo "-wifi have no gateway- reset wifi moduel"
				ifconfig wlan0 down
				/usr/sbin/wifi_station.sh stop
				killall -15 wifi_station.sh
				killall -9 udhcpc
				killall  -9 wpa_supplicant
				sleep 10
				station_start
				sleep 10
			else
				#time=`ping "$gateway" -c 1 | awk '{print $7}'`
				ping $gateway -c 2 #> /dev/null
				if [ $? != 0 ]; then
					times_count=`expr $times_count + 1`	
					echo "----###--->>>>times_out=$times_count" 
					if [ $times_count -gt 12 ];then  
						echo "-wifi can not ping gateway- reset wifi moduel"
#						killall -12 daemon 
#						sleep 5
						# kill apps, MUST use force kill
#						killall -9 daemon
#						killall -9 anyka_ipc
						times_count=0
						ifconfig wlan0 down
						/usr/sbin/wifi_station.sh stop
						killall -15 wifi_station.sh				
						killall -9 udhcpc
						killall  -9 wpa_supplicant
						sleep 1
						station_start
						sleep 5
					else
						echo "-wifi can not ping gateway- waiting-----------" 
					fi	
				else			
					times_count=0
					
#					check_ipc=`pgrep daemon`
#					if [ "$check_ipc" == "" ];then
#						daemon &
#						/usr/sbin/anyka_ipc.sh start
#					fi
					
				fi
			fi
			
		sleep 10
		#else
		#   break
		#fi
	done
#	rm -f $LOCK_NAME
#	trap - INT TERM EXIT
#else
#	echo "Failed to acquire lockfile: $LOCK_NAME." 
#	echo "Held by $(cat $LOCK_NAME)"
exit 1
#fi
