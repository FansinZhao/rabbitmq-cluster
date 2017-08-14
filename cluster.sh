#!/bin/bash

rabbitmq-plugins enable --offline rabbitmq_management

if [ -e cluster_init_success ]
then
    echo "已初始化,直接启动服务....."
    rabbitmq-server
elif [ -e cluster_init_failure ]
then
    echo "初始化失败,请重新创建容器..."
    exit -1
else
    DEFAULT_USER="admin"
    DEFAULT_PASS="admin"
    # 先启动,添加信息,然后重启
    rabbitmq-server -detached

    retry_times=5

    while [ ! -e cluster_inited ]
    do
        echo "开始初始化集群配置...."
        if [ $retry_times == 0 ]
        then
            echo "retry_times=$retry_times"
            touch cluster_init_failure
            touch cluster_inited
            continue
        fi
        let "retry_times--"
        if test -z $RABBITMQ_REMOTE_USER && test -z $RABBITMQ_REMOTE_PASS 
        then
            RABBITMQ_REMOTE_USER=$DEFAULT_USER
            RABBITMQ_REMOTE_PASS=$DEFAULT_PASS
        fi

        rabbitmqctl add_user $RABBITMQ_REMOTE_USER  $RABBITMQ_REMOTE_PASS
        
        if [ $? == 0 ]
        then
            touch cluster_init_success
            touch cluster_inited
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
    
    if [ -e cluster_init_success ]
    then
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
     else
       echo "初始化集群配置失败...请重新运行脚本尝试!" 
     fi   
fi
