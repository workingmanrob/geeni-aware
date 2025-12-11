# geeni-aware-factory-rootfs

![Geeni Mainboard](../pics/mainboard-back.jpg "Geeni Mainboard")

Backup of factory root filesystem.

Created by using an exclude file with the following content:
```
dev/*
mnt/*
proc/*
sys/*
tmp/*
var/run
```
Save that as /mnt/exclude which is where your sdcard should be mounted and create the tar in the same place:
```
tar cvf /mnt/geeni-aware-rootfs.tar / -X /mnt/exclude
``` 
