foo(){
docker run -d \
-v /var/lib/ceph:/var/lib/ceph \
-v /var/log/ceph:/var/log/ceph \
-v /var/run/ceph:/var/run/ceph \
-v /etc/ceph:/etc/ceph \
--privileged=true \
--network=host \
--pid=host \
--name=$1$2 \
--hostname $1$2 \
ceph:mini $1 $2
}

foo2(){
docker run -d --net=host \
-v /etc/ceph:/etc/ceph \
-v /var/lib/ceph/:/var/lib/ceph/ \
-e MON_IP=192.168.136.187 \
-e CEPH_PUBLIC_NETWORK=192.168.137.0/24 \
ceph:mini mon
}

foo $1 $2
