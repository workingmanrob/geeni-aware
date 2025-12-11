#! /bin/sh
### BEGIN INIT INFO
# File:				wifi_station.sh	
# Provides:         wifi station start, stop and connect
# Author:			
		
# Date:				2016-03-05
### END INIT INFO

PATH=$PATH:/bin:/sbin:/usr/bin:/usr/sbin
MODE=$1
cfgfile="/mnt/wifi_cfg.ini"
tmp_wifi_cfgfile="/tmp/wifi_info"

usage()
{
	echo "Usage: $0 start | stop | connect"
}

wifi_station_start()
{
	wpa_supplicant -B -iwlan0 -Dwext -c /etc/jffs2/wpa_supplicant.conf
}

using_static_ip()
{
	ipaddress=`awk 'BEGIN {FS="="}/\[ethernet\]/{a=1} a==1 &&
		$1~/^ipaddr/{gsub(/\"/,"",$2);gsub(/\;.*/, "", $2);
		gsub(/^[[:blank:]]*/,"",$2);print $2}' $cfgfile`
	netmask=`awk 'BEGIN {FS="="}/\[ethernet\]/{a=1} a==1 && 
		$1~/^netmask/{gsub(/\"/,"",$2);gsub(/\;.*/, "", $2);
		gsub(/^[[:blank:]]*/,"",$2);print $2}' $cfgfile`
	gateway=`awk 'BEGIN {FS="="}/\[ethernet\]/{a=1} a==1 && 
		$1~/^gateway/{gsub(/\"/,"",$2);gsub(/\;.*/, "", $2);
		gsub(/^[[:blank:]]*/,"",$2);print $2}' $cfgfile`

	ifconfig wlan0 $ipaddress netmask $netmask
	route add default gw $gateway
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
			udhcpc -i wlan0 
			sleep 1
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

wifi_station_do_connect()
{
	security=$1
	ssid=$2
	pswd=$3
	#### when debug, echo next line, other times don't print it
	echo "security=[$security] ssid=[$ssid] password=[$pswd]"
	ifconfig wlan0 up
	/usr/sbin/station_connect.sh "$security" "$ssid" "$pswd"
	ret=$?
	echo "/usr/sbin/station_connect.sh, return val:$ret"

	if [ $ret -eq 0 ];then
		i=0
		while [ $i -lt 30 ]
		do
			sleep 1
			OK=`wpa_cli -iwlan0 status | grep wpa_state`
			if [ "$OK" = "wpa_state=COMPLETED" ];then
				echo "[WiFi Station] $OK, security=$security ssid=$ssid pswd=$pswd"
				check_ip_and_start   #### get ip
				if [ $? -eq 0 ];then
					return 0
				else
					return 1
				fi
			else
				echo "wpa_cli still connectting, info[$i]: $OK"
			fi
			i=`expr $i + 1`
		done
		### time out judge
		if [ $i -eq 30 ];then
			echo "wpa_cli connect time out, try:$i, result:$OK"
			return 1
		fi
	else
		echo "station_connect.sh run failed, ret:$ret, check your arguments"
		return $ret
	fi
}

store_config_2_ini()
{
	update=0
	#### save security
	if [ -n "$1" ];then
		old_security=`awk 'BEGIN {FS="="}/\[wireless\]/{a=1} a==1&&
			$1~/^security/{gsub(/\"/,"",$2);gsub(/\;.*/, "", $2);
			gsub(/^[[:blank:]]*/,"",$2);print $2}' $cfgfile`
		#### store info by replace
		if [ "$1" != "$old_security" ];then
			echo "Save Security, new: $1"
			sed -i -e "/security/ s%= $old_security%= $1%" $cfgfile
			sync
			update=1
		fi
	fi

	#### save ssid
	if [ -n "$2" ];then
		old_ssid=`awk 'BEGIN {FS="="}/\[wireless\]/{a=1} a==1&&
			$1~/^ssid/{gsub(/\"/,"",$2);gsub(/\;.*/, "", $2);
		gsub(/^[[:blank:]]*/,"",$2);print $2}' $cfgfile`
		#### store info by replace
		if [ "$2" != "$old_ssid" ];then
			echo "Save Ssid, new: $2, old: $old_ssid"
			sed -i -e "/^ssid/ s/= $old_ssid/= $2/" $cfgfile
			sync
			update=1
		fi
	fi

	#### save password
	if [ -n "$3" ];then
		old_pwd=`awk 'BEGIN {FS="="}/\[wireless\]/{a=1} a==1&&
			$1~/^password/{gsub(/\"/,"",$2);gsub(/\;.*/, "", $2);
		gsub(/^[[:blank:]]*/,"",$2);print $2}' $cfgfile`
		#### store info by replace
		if [ "$3" != "$old_pwd" ];then
			echo "Save password, new: $3, old: $old_pwd"
			sed -i -e "/^password/ s/= $old_pwd/= $3/" $cfgfile
			sync
			update=1
		fi
	fi

	if [ $update -eq 1 ];then 
		echo "[WiFi Station] Save Config OK"
		#### for debug, show ini file first 23 line content
		head -23 $cfgfile
	fi
}

wifi_station_check_security()
{
	echo "check security, curval: $1"
	#### ���ܷ�ʽ��Ϊwpa��open�Ķ���Ϊ��Ҫ���»�ȡ
	if [ "$1" != "wpa" ] && [ "$1" != "open" ];then
		echo "[check security] invalid, val:$1"
		return 1
	elif [ -z "$1" ];then
		echo "[check security] invalid, val is null"
		return 1
	else
		echo "[check security] ok, val: $1"
		return 0
	fi
}

wifi_station_connect()
{
	echo "connect wifi station......"
	#### get ini info
	if [ -f $tmp_wifi_cfgfile ];then
		echo "reading wifi config from tmp"

		ssid=`awk -F '=' '/^ssid=/{print $2}' $tmp_wifi_cfgfile`
		password=`awk -F '=' '/^pswd=/{print $2}' $tmp_wifi_cfgfile`
		security=`awk -F '=' '/^sec=/{print $2}' $tmp_wifi_cfgfile`
		rm -rf $tmp_wifi_cfgfile
	else
		echo "reading wifi config from ini"
		ssid=`awk 'BEGIN {FS="="}/\[wireless\]/{a=1} a==1 && 
			$1~/^ssid/{gsub(/\"/,"",$2);gsub(/\;.*/, "", $2);
			gsub(/^[[:blank:]]*/,"",$2);print $2}' $cfgfile`
		password=`awk 'BEGIN {FS="="}/\[wireless\]/{a=1} a==1 && 
			$1~/^password/{gsub(/\"/,"",$2);gsub(/\;.*/, "", $2);
			gsub(/^[[:blank:]]*/,"",$2);print $2}' $cfgfile`
		security=`awk 'BEGIN {FS="="}/\[wireless\]/{a=1} a==1 &&
			$1~/^security/{gsub(/\"/,"",$2);gsub(/\;.*/, "", $2);
			gsub(/^[[:blank:]]*/,"",$2);print $2}' $cfgfile`
	fi

	############################# ��������ʱ ##########################
	#### ssid��Ϊ������Ϊ���������ù��������ù��Ļ�����������������
	while [ -n "$ssid" ]
	do
		#### ��������ʱ�������ܷ�ʽ������ȷ��ͨ����ǰssidȥ��������дΪ��ȷ�ġ�
		wifi_station_check_security "$security"
		#### ����ʱͨ��ssid�޷�ɨ�赽���ܷ�ʽ
		if [ $? -eq 1 ];then
			security="" #### clean the value
			break		#### �޷�ͨ��ɨ���ȡ���ܷ�ʽʱ������wpa��open��ʽ
		fi

		#### ��ʱ���в���ӦΪ�����ģ��������ӻ�ʧ��
		wifi_station_do_connect "$security" "$ssid" "$password"
		if [ $? -eq 0 ];then
			echo "[WiFi Station] Connect OK"
			store_config_2_ini "$security" "$ssid" "$password"
			return 0
		elif [ $? -eq 3 ];then
			echo "[WiFi Station] Normal connect failed, argments error"
			return 3
		else
			echo "[WiFi Station] Normal connect failed"
			return 1
		fi
	done
	############################# ��������ʱ ##########################

	#### if run to here, ˵��ssid�������˻���ĳЩԭ�����������޷���ȡ���ܷ�ʽ����ʱ��Ҫ����
	if [ -n "$ssid" ] && [ -z "$security" ];then
		wpa_cli -iwlan0 scan #### must scan
		sleep 1
		for security in wpa open
		do
			wifi_station_do_connect "$security" "$ssid" "$password"
			if [ 0 -eq $? ];then
				store_config_2_ini "$security" "" #### save config, ssid don't need save
				return 0
			elif [ $? -eq 3 ];then
				echo "$security connect, arguments error, please check"
				return 3
			fi
		done
		echo "[WiFi Station] Normal connect failed"
		return 1
	fi

	######## ͨ��smartlink ���� voicelink ��������ʱ ��������Ĵ��� ######## 
	#### if run to here, it means the mechine need to be config ####

	#### 1. get two encode types ssid from temporary file
	gbk_ssid=`cat /tmp/wireless/gbk_ssid`
	utf8_ssid=`cat /tmp/wireless/utf8_ssid`
	echo "##### gbk_ssid: $gbk_ssid"
	echo "##### utf-8_ssid: $utf8_ssid"

	#### 2. if pswd is empty, it means security is open, connect direct
	if [ -z "$password" ];then
		echo "connect open router, no password"
		for ssid in "$gbk_ssid" "$utf8_ssid"
		do
			wifi_station_do_connect open "$ssid" "" 	## the password fill empty
			if [ 0 -eq $? ];then
				store_config_2_ini open "$ssid"		## save config
				return 0
			elif [ $? -eq 3 ];then
				echo "wpa connect, arguments error, please check"
				return 3
			fi
		done
		echo "open security connect faile, please check"
		return 1
	fi

	#### 3. if security is not open, we only use wpa with two encode types ssid to try connect
	for ssid in "$gbk_ssid" "$utf8_ssid"
	do
		wifi_station_do_connect wpa "$ssid" "$password"
		if [ $? -eq 0 ];then
			store_config_2_ini wpa "$ssid" 
			return 0
		elif [ $? -eq 3 ];then
			echo "wpa connect, arguments error, please check"
			return 3
		fi
	done
	#### if run to here, that means the way wpa+gbk or wpa+utf8 connect failed, need to be reconfiguration
	echo "[WiFi Station] Connect Failed, try again !!!"
	return 1
}

wifi_station_stop()
{
	echo "stop wifi station......"
	killall wpa_supplicant
	killall udhcpc
	ifconfig wlan0 down
}


case "$MODE" in
	start)
		wifi_station_start
		;;
	stop)
		wifi_station_stop
		;;
	connect)
		wifi_station_connect
		return $?
		;;
	*)
		usage
		;;
esac
exit 0


