#!/bin/bash

cd $(dirname $0)

NAME=SFTPD
CurDir=$(pwd)
SftpdConf=./conf/sftpd.conf
TCP_Port=$(awk '/Port/{print $NF}'  ${SftpdConf})
IP=$(awk '/ListenAddress/{print $NF}' ${SftpdConf} )
test  "$IP" == "" && IP=127.0.0.1

if [ ! -f $SftpdConf ];then
        echo No $SftpdConf in $(pwd),Please check
        exit 1 
fi

Logfile=./log/monitor.log

localIP=$(/sbin/ip -f inet a|awk '/scope global eth/{print $2}'|sed  's#/24##')
cn=$(ps -ef|grep $0 |grep -v grep | wc -l)
if [ $cn -gt 3 ];then
        Alarmfile=../log/err.log
fi
function log(){
    test -d $(dirname $Logfile) || mkdir -p $(dirname $Logfile)
    echo $(date +'%F %T') $1 $2 $3 $4 $5 $6 $7 $8 |tee -a ${Logfile}
}



function check_service(){
    log "INFO" ": exec check CMD: nc -i 1 -w 1 -nv $IP ${TCP_Port} 2>&1 |grep Connected|wc -w"
    n=$(nc -i 1 -w 1 -nv $IP ${TCP_Port} 2>&1 |grep Connected|wc -w)

    if [ $n -eq 0 ];then
        log "ERR" ": $NAME is not exists! Try to restart it"
        $(which sshd) -f $SftpdConf
        sleep 2
        log $(nc -i 1 -w 1 -nv $IP ${TCP_Port} 2>&1 |grep Connected)
    else
        log "INFO" ": ${NAME} is running"
    fi
}

function check_users(){
        cd $CurDir
        oldusers=./conf/users.conf
        newusers=/data/sftp/sftpadmin/upload/users.conf

        /usr/bin/dos2unix $newusers

        log "INFO" ": check_users,new user config file: $newusers"
        if  [ $($(which diff) $oldusers $newusers | wc -l) -gt 1 ];then
                log "INFO" ": new sftp user to create  "
                cp $newusers $oldusers
                sh ./check_user.sh

        else
                log "INFO" ": no new users to create"
        fi
}


check_service
check_users
