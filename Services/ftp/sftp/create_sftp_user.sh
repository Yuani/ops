#!/bin/bash
cd $(dirname $0)

CurDir=$(pwd)

SftpConf=./conf/sftpd.conf
logfile=./log/create.log

NAME=$1
PASSWORD=$2
GROUP=sftp
if [ -z $NAME ];then
  echo "./$0  user_name"
  exit -1
fi


function log(){
  test -d $(dirname $logfile) || mkdir -p $(dirname $logfile)
  echo $(date +"%F %T") $1 $2 $3 $4 $5 $6 $7 $8 | tee -a  $logfile
}

log "INFO" ": Try to create new sftp user : $NAME"
yesno=$(id $NAME 2>&1| wc -w)
if [ $yesno -eq 3 ];then
  log "ERR" ": The sftp user $NAME is exist,Please change the account name."
  exit -2
fi

chrootDir=$(dirname $(awk '/ChrootDirectory/{print $NF;exit}'  ${SftpConf}))
test -z $chrootDir || chrootDir=/data/sftp

log "INFO" ": ChrootDirectory is $chrootDir/$NAME, Upload directory is $chrootDir/$NAME/upload" 
useradd -d $chrootDir/$NAME -g $GROUP  -s /usr/sbin/nologin $NAME
#mkdir -p $chrootDir/$NAME/.ssh
#chown $NAME:$GROUP  $chrootDir/$NAME/.ssh
mkdir -p $chrootDir/$NAME/upload
chown root.root $chrootDir/$NAME
chown $NAME:$GROUP  $chrootDir/$NAME/upload
chmod 755 $chrootDir/$NAME
#chmod 700 $chrootDir/$NAME/.ssh
#touch $chrootDir/$NAME/.ssh/authorized_keys
#chmod 400 $chrootDir/$NAME/.ssh/authorized_keys
# set the default manager key
# cat your_sftp_admin.pub >> $chrootDir/$NAME/.ssh/authorized_keys

cd $chrootDir/$NAME
rm -rf .bash_logout .bash_profile .bashrc .kshrc .zshrc .ssh 

cd $CurDir
echo "init the passwd: "
if [ -z $PASSWORD ];then
        PASSWORD=$(echo $(date +%s) |sha256sum|base64 |head -c 10)
fi

echo $PASSWORD | passwd --stdin $NAME
echo "Set Account not  Expiration"
chage -m 0 -M 99999 -I -1 -E -1 $NAME

log "INFO" ": Please add public keys to  $chrootDir/$NAME/.ssh/authorized_keys" 
log "INFO" ": Create SUCCESS!,the default passwd is : $PASSWORD"
