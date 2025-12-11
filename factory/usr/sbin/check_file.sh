#!/bin/sh

cfgfile="/etc/jffs2/"$1

if [ -f $cfgfile ];
then
    echo $cfgfile
else
    cp usr/local/$1 /etc/jffs2/
fi