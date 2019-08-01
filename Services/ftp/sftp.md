# SFTP
### SFTP简介
SFTP ，即 SSH 文件传输协议（ SSH File Transfer Protocol ），或者说是安全文件传输协议（ Secure File Transfer Protocol ）。
SFTP 是一个独立的 SSH 封装协议包，通过安全连接以相似的方式工作。它的优势在于可以利用安全的连接传输文件，还能遍历本地和远程系统上的文件系统。

在大多数情况下，优先选择 SFTP 而不是 FTP ，原因在于 SFTP 最基本的安全特性和能利用 SSH 连接的能力。
FTP 是一种不安全的协议，应当只有在特定的情况下或者你信任的网络中使用


#### 1、参考配置文件：  sftp.conf

    Port 65000
    ListenAddress xx.xx.xx.xx
    HostKey /etc/ssh/ssh_host_rsa_key
    HostKey /etc/ssh/ssh_host_ecdsa_key
    SyslogFacility AUTHPRIV
    AuthorizedKeysFile	.ssh/authorized_keys
    PasswordAuthentication no
    ChallengeResponseAuthentication no
    GSSAPIAuthentication yes
    GSSAPICleanupCredentials yes
    UsePAM yes
    X11Forwarding yes
    UsePrivilegeSeparation sandbox		# Default for new installations.
    UseDNS no
    PidFile /usr/local/services/sftp-1.0/log/sftp.pid
    Banner none
    MaxStartups 30:10:60
    #MaxSessions 10
    AcceptEnv LANG LC_CTYPE LC_NUMERIC LC_TIME LC_COLLATE LC_MONETARY LC_MESSAGES
    AcceptEnv LC_PAPER LC_NAME LC_ADDRESS LC_TELEPHONE LC_MEASUREMENT
    AcceptEnv LC_IDENTIFICATION LC_ALL LANGUAGE
    AcceptEnv XMODIFIERS
    Subsystem	sftp	internal-sftp
    Match Group ftp
      X11Forwarding no
      AllowTcpForwarding no
      ForceCommand internal-sftp
      ChrootDirectory /data/sftp/%u
  
  限制sftp用户的家目录/data/sftp/


#### 2、启动sftp服务 : /usr/sbin/sshd  -f sftp.conf
  
  
#### 3、新增用户脚本
 
    #cat create_sftp_user.sh
    #!/bin/bash
    cd $(dirname $0)
    SftpConf=./sftp.conf
    logfile=./log/create.log

    NAME=$1
    GROUP=ftp
    if [ -z $NAME ];then
      echo "./$0  user_name"
      exit -1
    fi

    function log(){
      echo $(date +"%F %T") $1 $2 $3 $4 $5 $6 $7 $8 | tee -a  $logfile
    }

    log "INFO" ": Try to create new sftp user : $NAME"
    yesno=$(id $NAME 2>&1| wc -w)
    if [ $yesno -eq 3 ];then
      log "ERR" ": The sftp user $NAME is exist,Please change the account name."
      exit -2
    fi

    chrootDir=$(dirname $(awk '/ChrootDirectory/{}END{print $NF}'  ${SftpConf}))
    test -z $chrootDir || chrootDir=/data/sftp

    log "INFO" ": ChrootDirectory is $chrootDir/$NAME, Upload directory is $chrootDir/$NAME/upload" 
    useradd -d $chrootDir/$NAME -g $GROUP  -s /usr/sbin/nologin $NAME
    mkdir -p $chrootDir/$NAME/.ssh
    mkdir -p $chrootDir/$NAME/upload
    chown root.root $chrootDir/$NAME
    chown $NAME:$GROUP  $chrootDir/$NAME/upload
    chown $NAME:$GROUP  $chrootDir/$NAME/.ssh
    chmod 755 $chrootDir/$NAME
    chmod 700 $chrootDir/$NAME/.ssh
    touch $chrootDir/$NAME/.ssh/authorized_keys
    chmod 400 $chrootDir/$NAME/.ssh/authorized_keys


    log "INFO" ": Please add public keys to  $chrootDir/$NAME/.ssh/authorized_keys" 
    log "INFO" ": Create SUCCESS!"

##### 脚本执行结果：

    # sh ./create_sftp_user.sh testftp05
    2018-08-16 17:14:43 INFO :Try to create new sftp user : testftp05
    2018-08-16 17:14:44 INFO : ChrootDirectory is /data/sftp/testftp05, Upload directory is /data/sftp/testftp05/upload
    2018-08-16 17:14:44 INFO : Please add public keys to /data/sftp/testftp05/.ssh/authorized_keys
    2018-08-16 17:14:44 INFO : Create SUCCESS!



#### 常见故障处理
ERR1  fatal: bad ownership or modes for chroot directory

    原因：用户的chroot dir权限不对
    解决：
        chown root.root $chrootDir/$NAME
        chmod 755 $chrootDir/$NAME
        chown $NAME:$GROUP  $chrootDir/$NAME/upload


ERR2:Disconnect: connection closed by remote host
    
    原因：连接数不够
    解决：修改sftpd.conf 中的配置项：MaxStartups
        MaxStartups 30:10:60  # 30:起始最大连接数30个， 10:超过30个的连接数时，会有10%的概率丢弃， 60:允许的最大连接数

ERR3: Too many authentication failures for test
    
    原因：认证失败次数太多
    解决：
    方法1: 调整 MaxAuthTries 的值，需要重启sshd
    方法2: 重置认证失败统计： pam_tally --reset --user <USERNAME> 
    
  
