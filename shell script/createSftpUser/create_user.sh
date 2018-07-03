# /bin/bash
function createGroup(){
egrep "$usergroup" /etc/group >& /dev/null
if [ $? -ne 0 ] ;then
   echo "create group $usergroup"
   groupadd $usergroup
fi
}

function createUser(){
   useradd -g $usergroup -d /afe_ftp -p $password -s /bin/false $username 2>/dev/null
   if [ $? -eq 0 ];then       
      gpasswd -a $sysuser  $usergroup 
      gpasswd -a $sysuser2 $usergroup
      echo "create user $username"
   else
      echo "create user $username fail" >&2
   fi
}

function createPath(){
   if [ ! -d $userpath ];then   
      mkdir -p $userpath
   fi
   chmod 770 $userpath
   chown $username:$usergroup $userpath
}

function editSshConfig(){
   sed -i "/Match Group/ s/$/,$usergroup/" $sshConfig
}

function delGroup(){
egrep "$usergroup" /etc/group >& /dev/null
if [ $? -eq 0 ] ;then
   groupdel $usergroup >& /dev/null
   if [ $? -eq 0 ] ;then
      echo "delete group $usergroup"
   else
      echo "delete group $usergroup fail!" >&2
   fi    
fi
}

function delUser(){
   userdel -r $username 2>/dev/null
   if [ $? -eq 0 -o $? -eq 12 ];then
      gpasswd -d $sysuser  $usergroup
      gpasswd -d $sysuser2 $usergroup
      echo "delete user $username"
   else
      echo "delete user $username fail!" >&2
   fi
}

function delSshConfig(){
  sed -i "/Match Group/ s/,$usergroup//" $sshConfig
}

################################################
# shell begin                                  
################################################
home=/home/yquser
sshConfig=/etc/ssh/sshd_config
perfix=/afe_ftp
date=`date +%Y%m%d`
file=$home/list/userlist_$date
sysuser=pab2biuser
sysuser2=pab2biuser2

cat $file | while read line
do
  username=`echo $line|awk '{print $1}'`
  usergroup=`echo $line|awk '{print $2}'`
  userpath=`echo $line|awk '{print $3}'`
  userpath=$perfix$userpath
  password=`echo $line|awk '{print $4}'|base64 -d|openssl passwd -stdin`
  id $username >& /dev/null
  if [ $? -eq 0 ] ;then 
     delUser
     delGroup
     delSshConfig
  fi
  createGroup 
  createUser
  createPath
  editSshConfig                
done
service sshd restart
