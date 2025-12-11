#!/bin/sh
# File:				update.sh	
# Provides:         
# Description:      recover system configuration
# Author:			aj

#play_recover_tip()
#{
#	ccli misc --tips "/usr/share/anyka_recover_device.mp3"
#tuya tips
#	ccli misc --tips "/usr/share/tuya_sound2.mp3"
#	sleep 3
#}

#recover factory config ini
rm -rf /etc/jffs2/anyka_cfg.ini
cp -rf /etc/jffs2/bak/factory_cfg.ini /etc/jffs2/anyka_cfg.ini
sync

#recover isp config ini
rm -rf /etc/jffs2/isp*.conf

#recover tuya specific configure
rm -rf /etc/jffs2/tuya_cfg.ini
rm -rf /etc/jffs2/tuya_user.db*
rm -rf /etc/jffs2/station.tuya

rm -rf /tmp/ak_ipc_start_time
rm -rf /tmp/ak_ptz_flag
sleep 1
killall -9 anyka_ipc


exit 0

#if not uninstall the wifi driver.Would start wifi failed.
#wifi_driver.sh uninstall

#after all done play tips
#play_recover_tip
