#!/bin/bash
#  pengteng
# 先找tf卡中.bin文件,然后找出需要升级的.bin文件
# 若没有.bin文件，则会找update.tar
# 升级之前，会对固件 Bundle 与 Version 进行判断。
# 当固件 Bundle 匹配，以及 Version 比当前固件版本高才能升级。
#


# 挂载一下 TF 卡检测 TF 卡目录是否有需要的配置文件。
sh /usr/sbin/tf_mount.sh
if [ $? -ne 0 ]; then
  echo "No TF-Card for F/W Update."
fi
FW_VERCODE_LAST="0.0.0.0"
TF_TAR=""
TF_OLD_OLD_FW_FILE="/mnt/update.tar"
TF_OLD_FW_FILE="/mnt/update/update.tar"
TF_FW_FILE=""
RAW_TAR=""

INFO_FILE="/tmp/update.ini"
INFO_SIZE=1024

INFO_BUNDLE=""
INFO_VERSION=""
INFO_AUTHOR=""
INFO_MD5=""

FW_FILE_SIZE=""
FW_RAW_SIZE=""

FW_RAW=
FW_MD5=""

# 获取当前固件版本号
CUR_VERSION=`cat /usr/share/VERSION`
CUR_BUNDLE=`cat /usr/share/BUNDLE`

# 参数 $1 传入关键字。
get_update_info()
{
  echo `cat $INFO_FILE | grep $1 | cut -d '=' -f 2 | awk '{print $1}'`
}

parse_update_info()
{
  INFO_BUNDLE=`get_update_info "bundle"`
  INFO_VERSION=`get_update_info "version"`
  INFO_AUTHOR=`get_update_info "author"`
  INFO_MD5=`get_update_info "md5"`
  
  if [ ${#INFO_BUNDLE} -gt 0 ] && [ ${#INFO_VERSION} -gt 0 ] && [ ${#INFO_MD5} -gt 0 ]; then
    return 0
  fi
  
  return 1
}

convert_version_code()
{
  echo $1 | awk -F '.' '{print $1 * 100000000 + $2 * 1000000 + $3 * 10000 + $4}'
}

VerSearch() 
{
  local Path=$1
  Path=${Path%*/}
  local FunRet=""
  local FileName=""
  if [ ! -d "${Path}" ]; then
    echo -e "\033[1;31m""The Version Path \"${Path}\" Is Not Exist.""\033[0m"
    return 0
  fi

  FunRet=`ls -a ${Path}/*.bin 2> /dev/null | wc -l`
  if [ ${FunRet} == "0" ]; then
    echo -e "\033[1;31m""The Version Path \"${Path}\" Is Not Exist *.bin.""\033[0m"
  else
    for FileName in `ls -a ${Path}/*.bin`
    do
      if [ x"${FileName}" != x"." -a x"${FileName}" != x".." ]; then
        if [ -f "${FileName}" ]; then
		   TF_TAR_CUR=${FileName};
		   FW_FILE_SIZE=`stat -c %s $TF_TAR_CUR`
           FW_RAW_SIZE=$(($FW_FILE_SIZE-$INFO_SIZE))
            # 从固件末端获取信息数据。
           dd if=$TF_TAR_CUR of=$INFO_FILE bs=1 skip=$FW_RAW_SIZE 2>>/dev/null
           cat $INFO_FILE
           # 解析固件信息。
           parse_update_info
		    # 判断版本号
    echo "  Current Bundle: $CUR_BUNDLE"
    echo "  TF-Card F/W Bundle: $INFO_BUNDLE"
    echo ""
          if [ $CUR_BUNDLE = $INFO_BUNDLE ]; then
		     FW_VERCODE=`convert_version_code $INFO_VERSION`
		     FW_VERCODE_LAST=`convert_version_code $FW_VERCODE_LAST`
		  # 只有满足固件版本比当前版本大才升级。
              if [ $FW_VERCODE -gt $FW_VERCODE_LAST ]; then
			     FW_VERCODE_LAST=$FW_VERCODE;
			     TF_TAR=$FileName;
			  fi
		  fi  
        fi
      fi
    done
	fi
	    #循环结束后找到待升级的文件TF_TAR
	    # 从固件中去掉信息部分，并计算 MD5 校验。
        # 在这个过程中，把固件数据放到内存，保证校验数据与内容的一致性，
        # 防止在升级拷贝过程中传输异常
		# 在三个文件当中按照判断优先级，把存在的用于升级。
		  # 判断文件名
    echo "      Current FileName: $FileName"
    echo ""
   if [ -f "/mnt/*.bin" ];then
	  TF_TAR=$FileName	
   elif [ -f $TF_OLD_FW_FILE ];then
      TF_TAR=$TF_OLD_FW_FILE
   elif [ -f $TF_OLD_OLD_FW_FILE ];then
      TF_TAR=$TF_OLD_OLD_FW_FILE
   fi
   # 升级文件
   if [ ${#TF_TAR} -eq 0 ]; then
	 echo "No F/W in TF-Card for Update."
   else
	FW_FILE_SIZE=`stat -c %s $TF_TAR`
	FW_RAW_SIZE=$(($FW_FILE_SIZE-$INFO_SIZE))
  
	# 从固件末端获取信息数据。
	dd if=$TF_TAR of=$INFO_FILE bs=1 skip=$FW_RAW_SIZE 2>>/dev/null
	cat $INFO_FILE
  
    # 解析固件信息。
    parse_update_info
    if [ $? -eq 0 ]; then
  
     # 判断版本号
     echo "      Current Bundle: $CUR_BUNDLE"
     echo "  TF-Card F/W Bundle: $INFO_BUNDLE"
     echo ""
  
     if [ $CUR_BUNDLE = $INFO_BUNDLE ]; then
  
    	# 判断版本号
		echo " Current Version: $CUR_VERSION"
		echo " TF-Card F/W Version: $INFO_VERSION"
		echo ""
      
      CUR_VERCODE=`convert_version_code $CUR_VERSION` 
      FW_VERCODE=`convert_version_code $INFO_VERSION`
      
      # 只有满足固件版本比当前版本大才升级。
      if [ $FW_VERCODE -gt $CUR_VERCODE ]; then
      
        # 输出固件信息，便于生产确认。
        echo "  Bundle: $INFO_BUNDLE"
        echo " Version: $INFO_VERSION"
        echo "  Author: $INFO_AUTHOR"
        echo "     Md5: $INFO_MD5"
        
        # 从固件中去掉信息部分，并计算 MD5 校验。
        # 在这个过程中，把固件数据放到内存，保证校验数据与内容的一致性，
        # 防止在升级拷贝过程中传输异常
        RAW_TAR='/tmp/update.tar'
        dd if=$TF_TAR of=$RAW_TAR bs=$FW_RAW_SIZE count=1 2> /dev/null
        
        # 计算当前文件 MD5 校验值。
        FW_MD5=`md5sum $RAW_TAR | awk '{print $1}'`
        echo "File Md5: $FW_MD5"
        
        # 匹配 MD5 校验。
        if [ "$INFO_MD5" = "$FW_MD5" ]; then
          # 通过脚本升级固件。
          sh /usr/sbin/update_tmp.sh
        else
          echo "F/W Md5 Error."
        fi
      else
        echo "F/W Version Up-to-Date."
      fi
    else
      echo "F/W Bundle Not Matchable."
    fi
  else
    # 解析固件内容失败。
    echo "Get F/W Info Failed."
  fi
fi

}

VerSearch /mnt/

# 卸载 TF 卡挂载，保证会话完整性。
sh /usr/sbin/tf_umount.sh
