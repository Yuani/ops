SFTP 使用指引
### 1、SFTP 目录结构

    tree sftp-1.0/
    sftp-1.0/
    |-- check_user.sh
    |-- conf
    |   |-- sftpd.conf
    |   `-- users.conf
    |-- create_sftp_user.sh
    |-- log
    |   |-- create.log
    |   |-- monitor.log
    |   `-- sftp.pid
    `-- monitor_sftpd.sh

### 2、配置计划任务：
crontab -e

    # sftp monitor 
    */5 * * * *  sh /usr/local/services/sftp-1.0/monitor_sftpd.sh > /dev/null 2>&1 &
    
### 3、管理账号：

    echo 'sftpadmin:adnajk8673' >>/data/sftp/sftpadmin/upload/users.conf
    sh monitor_sftpd.sh
    
### 4、其他用户管理
使用管理账号sftpadmin 连接
