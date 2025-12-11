#! /bin/sh
### BEGIN INIT INFO
# File:				station_connect.sh	
# Description:      wifi station connect to AP 
# Author:			gao_wangsheng
# Email: 			gao_wangsheng@anyka.oa
# Date:				2012-8-2
### END INIT INFO

MODE=$1
GSSID="$2"
SSID=\'\"$GSSID\"\'
GPSK="$3"
PSK=\'\"$GPSK\"\'
KEY=$PSK
KEY_INDEX=$4
KEY_INDEX=${KEY_INDEX:-0}
NET_ID=
PATH=$PATH:/bin:/sbin:/usr/bin:/usr/sbin

usage()
{
	echo "Usage: $0 mode(wpa|wep|open) ssid password"
	exit 3
}

refresh_net()
{
	#### remove all connected netword
	while true
	do
		NET_ID=`wpa_cli -iwlan0 list_network\
			| awk 'NR>=2{print $1}'`

		if [ -n "$NET_ID" ];then
			wpa_cli -p/var/run/wpa_supplicant remove_network $NET_ID
		else
			break
		fi
	done
	wpa_cli -p/var/run/wpa_supplicant ap_scan 1
}

station_connect()
{	

	sh -c "wpa_cli -iwlan0 set_network $1 scan_ssid 1"
	wpa_cli -iwlan0 enable_network $1
	wpa_cli -iwlan0 select_network $1
#	wpa_cli -iwlan0 save_config
	
}
check_ip_and_start()
{
	echo "check ip and start"

	dhcp=`awk 'BEGIN {FS="="}/\[ethernet\]/{a=1} a==1 && 
		$1~/^dhcp/{gsub(/\"/,"",$2);gsub(/\;.*/, "", $2);
		gsub(/^[[:blank:]]*/,"",$2);print $2}' $cfgfile`
	status=
	i=0
	while [ $i -lt 2 ]
	do
		if [ $dhcp -eq 1 ];then
			echo "using dynamic ip ..."
			killall udhcpc
			udhcpc -i wlan0 &
			sleep 3
		elif [ $dhcp -eq 0 ];then
			echo "using static ip ..."
			using_static_ip
			sleep 1
		fi
		status=`ifconfig wlan0 | grep "inet addr:"`
		if [ "$status" != "" ];then
			break
		fi
		i=`expr $i + 1`
	done
	
	if [ $i -eq 2 ];then
		echo "[WiFi Station] fails to get ip address"
		return 1
	fi

	return 0
}
connet_wpa()
{
	NET_ID=""
	refresh_net

	NET_ID=`wpa_cli -iwlan0 add_network`
	sh -c "wpa_cli -iwlan0 set_network $NET_ID ssid $SSID"
	wpa_cli -iwlan0 set_network $NET_ID key_mgmt WPA-PSK
	sh -c "wpa_cli -iwlan0 set_network $NET_ID psk $PSK"

	station_connect $NET_ID
	
	
		i=0
		while [ $i -lt 8 ]
		do
			sleep 3
			OK=`wpa_cli -iwlan0 status | grep wpa_state`
			if [ "$OK" = "wpa_state=COMPLETED" ];then
				echo "[WiFi Station] $OK, security=$security ssid=$ssid pswd=$pswd"
				#check_ip_and_start   #### get ip
				killall udhcpc
			    udhcpc -i wlan0 &
				if [ $? -eq 0 ];then
					return 0
				else
					return 1
				fi
			else
				echo "wpa_cli still connectting, info[$i]: $OK"
			fi
			if [ "$OK" = "wpa_state=INTERFACE_DISABLED" ];then
				ifconfig wlan0 up
			fi
			i=`expr $i + 1`
		done
		### time out judge
		if [ $i -eq 8 ];then
			echo "wpa_cli connect time out, try:$i, result:$OK"
			return 1
		fi
}

connet_wep()
{
	NET_ID=""
	refresh_net
	if [ "$NET_ID" = "" ];then
	{
		NET_ID=`wpa_cli -iwlan0 add_network`
		sh -c "wpa_cli -iwlan0 set_network $NET_ID ssid $SSID"
		wpa_cli -iwlan0 set_network $NET_ID key_mgmt NONE
		keylen=$echo${#KEY}
		
		if [ $keylen != "9" ] && [ $keylen != "17" ];then
		{
			wepkey1=${KEY#*'"'}
			wepkey2=${wepkey1%'"'*};
			KEY=$wepkey2;
			echo $KEY
		}
		fi				
		sh -c "wpa_cli -iwlan0 set_network $NET_ID wep_key${KEY_INDEX} $KEY"
	}
	elif [ "$GPSK" != "" ];then
	{
		keylen=$echo${#KEY}
		if [ $keylen != "9" ] && [ $keylen != "17" ];then
		{
			wepkey1=${KEY#*'"'}
			wepkey2=${wepkey1%'"'*};
			KEY=$wepkey2;
			echo $KEY
		}
		fi	
		sh -c "wpa_cli -iwlan0 set_network $NET_ID wep_key${KEY_INDEX} $KEY"
	}
	fi

	station_connect $NET_ID
}

connet_open()
{
	NET_ID=""
	refresh_net
	
	NET_ID=`wpa_cli -iwlan0 add_network`
	sh -c "wpa_cli -iwlan0 set_network $NET_ID ssid $SSID"
	wpa_cli -iwlan0 set_network $NET_ID key_mgmt NONE

	station_connect $NET_ID
}

connect_adhoc()
{
	NET_ID=""
	refresh_net
	if [ "$NET_ID" = "" ];then
	{
		wpa_cli ap_scan 2
		NET_ID=`wpa_cli -iwlan0 add_network`
		sh -c "wpa_cli -iwlan0 set_network $NET_ID ssid $SSID"
		wpa_cli -iwlan0 set_network $NET_ID mode 1
		wpa_cli -iwlan0 set_network $NET_ID key_mgmt NONE
	}
	fi

	station_connect $NET_ID
}

check_ssid_ok()
{
	if [ "$GSSID" = "" ]
	then
		echo "Incorrect ssid!"
		usage
	fi
}

check_password_ok()
{
	if [ "$GPSK" = "" ]
	then
		echo "Incorrect password!"
		usage
	fi
}


#
# main:
#
killall wpa_supplicant
if [ -d "/tmp/wireless" ]
then
	rm /tmp/wireless -rf
	mkdir /tmp/wireless
	wpa_supplicant -B -iwlan0 -Dwext -c /etc/jffs2/wpa_supplicant.conf
else
    mkdir /tmp/wireless
	wpa_supplicant -B -iwlan0 -Dwext -c /etc/jffs2/wpa_supplicant.conf
fi
echo $0 $*
case "$MODE" in
	wpa)
		check_ssid_ok
		check_password_ok
		connet_wpa 
		;;
	wep)
		check_ssid_ok
		check_password_ok
		connet_wep 
		;;
	open)
		check_ssid_ok
		connet_open 
		;;
	adhoc)
		check_ssid_ok
		connect_adhoc
		;;
	*)
		usage
		;;
esac
exit 0

