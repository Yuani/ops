# cat check_user.sh 
#!/bin/bash

cd $(dirname $0)

CMD_createUser=create_sftp_user.sh
CMD_PASSWD=$(which passwd)

users=./conf/users.conf
illegalUser="root sftp user_00 user_01 user_02 ftp admin tdbank tdwadmin hadoop_user wwwrun systemd-network ociq  polkitd  secu nfsnobody nobody"
if [ ! -f $users ];then
        echo No $users in $(pwd),Please check.
        exit 1 
fi

logfile=./log/create.log
test -d $(dirname $logfile) || mkdir -p $(dirname $logfile)
function log(){
  echo $(date +"%F %T") $1 $2 $3 $4 $5 $6 $7 $8 | tee -a  $logfile
}

GroupName=sftp
ftpUsers=$(lid  -g  $GroupName  |awk -F'(' '{printf("%s",$1)}')
test $? -eq 1 &&  (echo No group $GroupName;exit 2)
echo $ftpUsers 
if [ -z "$ftpUsers"  ];then
        log "WARN" "No ftp user, Please check the group  $GroupName"
        #exit 3
fi




# add new sftp user 
sftpuser=$(awk  '{printf("%s ",$1)}' $users)
for user in $sftpuser
do

        NAME=$(echo $user|cut -d':' -f 1 )
        PASSWD=$(echo $user|cut -d':' -f 2 )

        log "INFO" ":$NAME $PASSWD"
        illegal=$(echo  $illegalUser | grep $NAME | wc -l )
        if [  $illegal -ne 0 ];then
                log "WARN" ": illegal user : $illegalUser, Name:$NAME"
                continue 
        fi

        yesno=$(id $NAME 2>&1| wc -w)
        if [ $yesno -eq 3 ];then
                log "WARN" ": The sftp user $NAME is exist."
                log "INFO" ": reset Password for $NAME"
                echo $PASSWD | ${CMD_PASSWD}  --stdin $NAME 
        else
                log 'INFO' "Add new sftp user: $NAME"
                sh   ${CMD_createUser} $NAME $PASSWD
                test $(grep -w $NAME /etc/script_user | wc -l ) -gt 0 || echo $NAME >> /etc/script_user 
        fi

done 


# del old sftp user
for NAME in $ftpUsers
do
        illegal=$(echo  $illegalUser | grep $NAME | wc -l )
        if [ $illegal -ne 0 ];then
                log "WARN" ": illegal user : $illegalUser, Name:$NAME"
                continue
        fi

        log "INFO" ": check old user: $NAME" 
        if [ $(grep $NAME $users | wc -l ) -eq 0 ];then
                log "WARN" " del user $NAME"
                userdel  $NAME
                sed -i "/$NAME/d"  /etc/script_user
        fi

done
