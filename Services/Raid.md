# RAID 磁盘阵列



### 1、更换坏损磁盘
#### 更换磁盘步骤
    
    1、标记为failed：  mdadm  /dev/md0  -f  磁盘
    2、删除failed磁盘：mdadm  /dev/md0  -r  磁盘
    3、拔出failed的物理磁盘，并插入新的物理磁盘
    4、格式化新盘: mkfs.ext4  新磁盘
    5、mdadm 添加新盘
    
    
#### 1.1 查看raid信息

    # cat /proc/mdstat 
    Personalities : [linear] [raid0] [raid1] [raid10] [raid6] [raid5] [raid4] 
    md1 : active raid5 sdm[5] sdl[4] sdk[3] sdj[2] sdi[1] sdh[0]
          9766917440 blocks super 1.2 level 5, 64k chunk, algorithm 2 [6/6] [UUUUUU]
          bitmap: 0/4 pages [0KB], 262144KB chunk

    md0 : active raid5 sdg[5] sdf[4](F) sde[3] sdd[2] sdc[1] sdb[0]
          9766917440 blocks super 1.2 level 5, 64k chunk, algorithm 2 [6/5] [UUUU_U]
          bitmap: 4/4 pages [16KB], 262144KB chunk

#### 1.2 从以上信息，可以看到 md0中的 sdf 磁盘存在问题，先将sdf 标记为失败：
    # mdadm --manage /dev/md0 --fail /dev/sdf
    mdadm: set /dev/sdf faulty in /dev/md0
      
#### 1.3 删除 md0中的 sdf ：
    # mdadm --manage /dev/md0 --remove  /dev/sdf
    mdadm: hot removed /dev/sdf from /dev/md0
    
#### 1.4 再次查看raid信息，md0 中的 sdf 已经不存在了
    # cat /proc/mdstat 
    Personalities : [linear] [raid0] [raid1] [raid10] [raid6] [raid5] [raid4] 
    md1 : active raid5 sdm[5] sdl[4] sdk[3] sdj[2] sdi[1] sdh[0]
          9766917440 blocks super 1.2 level 5, 64k chunk, algorithm 2 [6/6] [UUUUUU]
          bitmap: 0/4 pages [0KB], 262144KB chunk

    md0 : active raid5 sdg[5] sde[3] sdd[2] sdc[1] sdb[0]
          9766917440 blocks super 1.2 level 5, 64k chunk, algorithm 2 [6/5] [UUUU_U]
          bitmap: 4/4 pages [16KB], 262144KB chunk
      
      
#### 1.5 向 md0中添加 sdf ：
    # mdadm --manage /dev/md0 --add  /dev/sdf
    mdadm: addes /dev/sdf 
    
#### 1.6 Raid5 扩容
    # raid5的Grow模式， -n 代表RAID 真正成员的个数
    # 假设RAID5真正成员是3个，后来我们又添加了一个备用成员/dev/sdf进去
    # 第一步：添加磁盘
    # 第二部
    # 假设RAID5真正成员是3个，后来我们又添加了一个备用成员/dev/sdf进
    mdadm -G /dev/md0  -n4   #这样就把热备的分区添加到了raid成员中了，容量也扩大了哦


    
