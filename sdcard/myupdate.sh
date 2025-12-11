#! /bin/sh

# Backup the original contents of /etc/jffs2 to the sdcard
if [[ ! -d /mnt/jffs2 ]]; then
	cp -a /etc/jffs2 /mnt/
fi

if [[ ! -f /mnt/bak/shadow ]]; then
	# backup the original again just in case
	mv /etc/jffs2/shadow /etc/jffs2/shadow.org
	if [[ ! -d /mnt/bak ]]; then
		mkdir /mnt/bak
	fi
	cp /mnt/shadow /mnt/bak/
	# move modified shadow file to set root password = cosmicpower
	mv /mnt/shadow /etc/jffs2/
fi

/mnt/wifi_manage.sh start_sta

sleep 10

/mnt/dropbear/dropbearmulti dropbear -r /mnt/dropbear/dropbear_ecdsa_host_key &

sleep 10

# forever loop to keep script running - prevents system from starting camera services
while true; do
	sleep 600
done
