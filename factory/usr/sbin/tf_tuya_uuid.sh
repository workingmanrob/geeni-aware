#! /bin/sh
#
# 当前脚本实现设备通过 TF 卡把涂鸦 UUID 加载到本地。
# 其中判定 TF 卡中 tuya.conf 文件（兼容旧版本策略，并把文件拷贝到本地）。
# 判定 _ak39_tuya_uuid.ini 文件，并把它拷贝到临时目录，用于临时序列号策略。
#


# 挂载一下 TF 卡检测 TF 卡目录是否有需要的配置文件。
sh /usr/sbin/tf_mount.sh
if [ $? -ne 0 ]; then
  echo "No TF-Card for Tuya UUID Setup."
fi


TF_DIR="/mnt/"
TMP_DIR="/tmp/"
CFG_DIR="/etc/jffs2/"

# 旧版本涂鸦 UUID 文件名称。
OLD_UUID_FILE=tuya.conf
# 新版本涂鸦 UUID 文件名称
NEW_UUID_FILE=_ak39_tuya_uuid.ini

TF_OLD_UUID="$TF_DIR$OLD_UUID_FILE"
TF_NEW_UUID="$TF_DIR$NEW_UUID_FILE"

DANALE_UUID="$CFG_DIR"danale.conf
TMP_UUID="$TMP_DIR$NEW_UUID_FILE"

validate_tmp_uuid()
{
  UUID=`cat $TMP_UUID | grep -e uuid | cut -d '=' -f 2 | awk '{print $1}'`
  AUZKEY=`cat $TMP_UUID | grep -e auth_key -e auzkey | cut -d '=' -f 2 | awk '{print $1}'`
  PID=`cat $TMP_UUID | grep -e pid | cut -d '=' -f 2 | awk '{print $1}'`

# UUID 合法长度 20 位。
# AUZKEY 合法长度 32 位。
# PID 合法长度 8 - 16 位。  
  
  # 当 PID 非法时把 PID 至于空
  if [ ${#PID} -ge 8 ] && [ ${#PID} -le 16 ]; then
    PID=$PID
  else
    PID=""
  fi

  # KEY 与 AUZKEY 必须合法。
  if [ ${#UUID} -eq 20 ] && [ ${#AUZKEY} -eq 32 ]; then
  
    # 美化 UUID 文件格式
    echo "" > $TMP_UUID
    echo "        uuid = $UUID" >> $TMP_UUID
    echo "      auzkey = $AUZKEY" >> $TMP_UUID
    echo "         pid = $PID" >> $TMP_UUID
  
    return 0
  else
    echo "Valid UUID Failed."
    return 1
  fi
}

# 强制加载 TF 卡的涂鸦 UUID 逻辑。                                                                                               
if [ -f $TF_OLD_UUID ];then        
                                   
# 先把 TF 文件放到 TMP 析。        
   dd if="$TF_OLD_UUID" of="$TMP_UUID" bs=256 count=1 2> /dev/null  
   validate_tmp_uuid
   
  if [ $? -eq 0 ]; then
   
    # UUID 文件合法，覆盖原来大拿配置文件，用于兼容产测工具。
    rm -f $DANALE_UUID
    mv $TMP_UUID $DANALE_UUID
    echo "Force Tuya Uuid from '$TMP_UUID'."
    cat $DANALE_UUID
    
  else

    # UUID 文件非法，删除临时文件。
    rm -f $TMP_UUID  
  fi             
       
# 使用临时 TF 卡涂鸦 UUID 逻辑。
elif [ -f "$TF_NEW_UUID" ];then

  dd if="$TF_NEW_UUID" of="$TMP_UUID" bs=256 count=1 2> /dev/null
  validate_tmp_uuid
  
  if [ $? -eq 0 ]; then
   
    # UUID 文件合法。
    echo "Load Temporary Tuya Uuid for '$TMP_UUID'."
    cat "$TMP_UUID"
    
  else

    # UUID 文件非法，删除临时文件。
    rm -f "$TMP_UUID"  
  fi   
fi

                                                                                                                                
                                      
# 卸载 TF 卡挂载，保证会话完整性。
sh /usr/sbin/tf_umount.sh

