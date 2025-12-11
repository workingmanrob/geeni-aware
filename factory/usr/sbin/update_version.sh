#! /bin/sh
### BEGIN INIT INFO
# File:				led.sh	
# Description:      control led status
# Author:			gao_wangsheng
# Email: 			gao_wangsheng@anyka.oa
# Date:				2012-9-6
### END INIT INFO



#
# main:
#

Ver=`cat /usr/share/VERSION`

echo "$Ver"

sed -i "s/^soft_version.*/soft_version= $Ver/"		/etc/jffs2/anyka_cfg.ini
sed -i "s/^soft_version.*/soft_version= $Ver/"		/etc/jffs2/bak/factory_cfg.ini

exit 0






