#BASE IMAGE
FROM centos:7
ADD pki /etc/pki
ADD yum.repos.d /etc/yum.repos.d
RUN yum makecache
RUN yum -y install leveldb
RUN yum -y install libaio
RUN yum -y install gperftools
RUN yum -y install fuse-devel
RUN yum -y install redhat-lsb
RUN rm -rf /usr/include
RUN yum -y install parted
RUN yum -y install xfsprogs
RUN yum -y install kmod
RUN yum -y install gdisk
RUN yum -y install lvm2
RUN yum -y clean all

ADD ftp://172.17.110.41/pub/ceph/boost-1.63-part-devel.tar.gz /tmp
ADD ftp://172.17.110.41/pub/ceph/201808/ceph-rpms-10.2.3-422.c4efb2363e4c2ad165913673e85278534de43890-el7-part.tar.gz /tmp
RUN find /tmp -name *.rpm | xargs rpm -ivh --nodeps --force
RUN rm -rf /tmp/*

FROM busybox:1
COPY --from=0 / /
