#! /bin/sh


check_wifi_driver()
{
    a=`ifconfig -a | grep wlan0 | wc -l`
    return $a
}

check_wired_driver()
{
    a=`ifconfig -a | grep eth0 | wc -l`
    return $a
}


## 先尝试插入 8189FS
#echo "Try Wi-Fi Driver RTL8189FS."
#insmod /usr/modules/sdio_wifi.ko
#insmod /usr/modules/8189fs.ko
echo 0 > /sys/user-gpio/wifi_power         #wifi power on
echo "Try Wi-Fi Driver RTL8188FTV."
insmod /usr/modules/otg-hs.ko
sleep 1
insmod /usr/modules/rtl8188fu.ko
sleep 2

check_wifi_driver
if [ $? = 0 ]; then

   # rmmod 8189fs
   # rmmod sdio_wifi
    rmmod rtl8188fu
    rmmod otg-hs
	echo 1 > /sys/user-gpio/wifi_power         #wifi power off
	sleep 1
    echo "Probe Wi-Fi Driver RTL8188FTV Failed." 
    echo "Try again."
	
    echo 0 > /sys/user-gpio/wifi_power         #wifi power on 
    insmod /usr/modules/otg-hs.ko
    sleep 1
    insmod /usr/modules/rtl8188fu.ko
    sleep 2
    
    check_wifi_driver
    if [ $? = 0 ]; then
        rmmod rtl8188fu
        rmmod otg-hs
		echo 1 > /sys/user-gpio/wifi_power         #wifi power off
        echo "Probe Wi-Fi Driver RTL8188FTV Failed." 
    fi
    
fi

# 检查一下当前 WIFI 的 MAC 地址是否登记了，如果没有的话根据当前网卡 MAC 记录一个。
MAC_FMT="00:01:02:03:04:05"
MAC_FILE="/etc/jffs2/wifimac.txt"
CUR_MAC=`ifconfig -a | grep wlan0 | head -1 | awk '{print $5}'`

if [ -f $MAC_FILE ]; then

  FIX_MAC=`cat $MAC_FILE`;
  echo "Fixed MAC" $FIX_MAC;

else

  echo "WiFi MAC Not Config.";

#如果当前 MAC 地址合法的话登记到存储区。
  if [ ${#CUR_MAC} -eq ${#MAC_FMT} ]; then
    echo "Mark MAC" $CUR_MAC
    echo $CUR_MAC > $MAC_FILE
  fi

fi

# 插入有线网卡。
echo "Try Wired Ethernet Driver."
insmod /usr/modules/otg-hs.ko
sleep 1
insmod /usr/modules/usbnet.ko
sleep 1
insmod /usr/modules/asix.ko
sleep 1

# 启动网卡
ifconfig wlan0 up 2> /dev/null
ifconfig wlan0 mode monitor 2> /dev/null
ifconfig eth0 up 2> /dev/null

