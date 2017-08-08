# 基于官方rabbitmq镜像实现集群

这个镜像根据官方rabbitmq镜像,经过简单的处理,可以实现直接进行集群,方便测试或演示使用.

[Docker Hub 镜像](https://hub.docker.com/r/fansin/rabbitmq-cluster/) 

基本使用方式可以完全参考[rabbitmq官方镜像](https://hub.docker.com/_/rabbitmq/)

# 使用方式

1 用作非集群节点,默认自动创建一个远程管理员用户.用户/密码: `admin/admin`

    docker run --rm -d --hostname my-rabbit-cluster --name my-rabbit-cluster -e RABBITMQ_ERLANG_COOKIE='secret cookie here' rabbitmq-cluster

如果需要自定义用户,只需要重写两个变量`RABBITMQ_REMOTE_USER`和`RABBITMQ_REMOTE_PASS`

    docker run --rm -d --hostname my-rabbit-cluster --name my-rabbit-cluster -e RABBITMQ_ERLANG_COOKIE='secret cookie here' -e docker run --rm -d --hostname my-rabbit-cluster --name my-rabbit-cluster -e RABBITMQ_ERLANG_COOKIE='secret cookie here' rabbitmq-cluster
=admin -e RABBITMQ_REMOTE_PASS=admin rabbitmq-cluster



2 用作集群节点,加入已创建节点集群中,,使用`--link my-rabbit-cluster`连接两个容器,JOIN_CLUSTER表示加入的集群节点.注意保证RABBITMQ_ERLANG_COOKIE一致.

    docker run --rm -d --link my-rabbit-cluster --hostname my-rabbit-cluster-1 --name my-rabbit-cluster-1 -e RABBITMQ_ERLANG_COOKIE='secret cookie here' -e JOIN_CLUSTER=my-rabbit-cluster rabbitmq-cluster

可以设置持久化类型,通过设置`-e CLUSTER_NODE_TYPE=ram`

    docker run --rm -d --link my-rabbit-cluster --hostname my-rabbit-cluster-2 --name my-rabbit-cluster-2 -e RABBITMQ_ERLANG_COOKIE='secret cookie here' -e JOIN_CLUSTER=my-rabbit-cluster -e CLUSTER_NODE_TYPE=ram rabbitmq-cluster

# 简单说明

1 使用--link 避免设置hosts
2 集群方式跟官方说明一致

    rabbitmqctl stop_app
    rabbitmqctl join_cluster rabbit@my-rabbit
    rabbitmqctl start_app


# 已知异常
1 由于rabbitmq-server需要先启动,才能添加用户,尽管做了重试设置,但仍有一定概率出现无法创建用户异常,请查看日志,保证有ip输出.
2 rabbitmq-server 未发现日志配置选项,而官方镜像只做了stdout,所以为了查看日志,rabbitmq-server重启了一次.

有疑问可以发issue或者直接联系我 171388204@qq.com

# 感谢
