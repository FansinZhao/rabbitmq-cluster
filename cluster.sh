#!/bin/bash

rabbitmq-server -detached

retry_times=5
start_success=-1
while [ $start_success == -1 ]
do
    if [ $retry_times == 0 ]
    then
        echo "retry_times=$retry_times"
        start_success=0
        continue
    fi
    let "retry_times--";
    echo "添加远程用户..." 
    if test -z $RABBITMQ_REMOTE_USER && test -z $RABBITMQ_REMOTE_PASS 
    then
        RABBITMQ_REMOTE_USER="admin"
        RABBITMQ_REMOTE_PASS="admin"
    fi

    rabbitmqctl add_user $RABBITMQ_REMOTE_USER  $RABBITMQ_REMOTE_PASS
    
    if [ $? == 0 ]
    then
        start_success=0
    else
        sleep 3s
        continue
    fi   
    rabbitmqctl set_user_tags $RABBITMQ_REMOTE_USER administrator
    rabbitmqctl authenticate_user $RABBITMQ_REMOTE_USER  $RABBITMQ_REMOTE_PASS
    rabbitmqctl set_permissions -p / $RABBITMQ_REMOTE_USER '.*' '.*' '.*'
    rabbitmqctl list_user_permissions $RABBITMQ_REMOTE_USER

    ip=$(cat /etc/hosts | grep `hostname`|awk '{print $1}')
    echo -e "添加管理员用户成功......\n $ip $RABBITMQ_REMOTE_USER/$RABBITMQ_REMOTE_PASS"



    if test $JOIN_CLUSTER
    then
        echo "加入集群..."
        rabbitmqctl stop_app
        
        if test -z $CLUSTER_NODE_TYPE
        then
            rabbitmqctl join_cluster rabbit@$JOIN_CLUSTER
        else
            rabbitmqctl join_cluster --$CLUSTER_NODE_TYPE rabbit@$JOIN_CLUSTER
        fi   
        rabbitmqctl start_app
        rabbitmqctl cluster_status
    fi
done
#重启 可以优化,暂时没有找到方法
rabbitmqctl stop
sleep 3s
if [ $? == 0 ]
then
    rabbitmq-server
else
    sleep 3s
    rabbitmq-server
fi









