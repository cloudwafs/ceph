# CEPH DAEMON IMAGE
#FROM ceph/daemon-base:master-jewel-centos-7-x86_64
ARG baseimage=eisoo/ceph-base:latest
FROM ${baseimage}

# Who is the maintainer ?
LABEL maintainer="Erwan Velu <evelu@redhat.com>"

# What is the actual release ? If not defined, this equals the git branch name
LABEL RELEASE="master"

# What was the url of the git repository
LABEL GIT_REPO="https://github.com/ceph/ceph-container"

# What was the git branch used to build this container
LABEL GIT_BRANCH="master"

# What was the commit ID of the current HEAD
LABEL GIT_COMMIT="9cd66e3e571bded14b3ae138bdc128fc94b46697"

# Was the repository clean when building ?
LABEL GIT_CLEAN="False"

# What CEPH_POINT_RELEASE has been used ?
LABEL CEPH_POINT_RELEASE="-10.2.3"

#======================================================
# Install ceph and dependencies, and clean up
#======================================================


# Escape char after immediately after RUN allows comment in first line
RUN \
    # Install all components for the image, whether from packages or web downloads.
    # Typical workflow: add new repos; refresh repos; install packages; package-manager clean;
    #   download and install packages from web, cleaning any files as you go.
    echo 'Install packages' && \
      yum install -y wget unzip util-linux python-setuptools udev device-mapper && \
      yum install -y \
          sharutils \
          lsof \
           \
           \
          kubernetes-client \
          etcd \
          s3cmd && \
    # Centos 7 doesn't have confd/forego packages, so install them from web
    echo 'Web install confd' && \
      CONFD_VERSION=0.16.0 && \
      # Assume linux
      CONFD_ARCH=linux-amd64 && \
      wget -O /usr/local/bin/confd \
        "https://github.com/kelseyhightower/confd/releases/download/v${CONFD_VERSION}/confd-${CONFD_VERSION}-${CONFD_ARCH}" && \
      chmod +x /usr/local/bin/confd && mkdir -p /etc/confd/conf.d && mkdir -p /etc/confd/templates && \
    echo 'Install forego' && \
      # Assume linux
      FOREGO_ARCH=linux-amd64 && \
      wget -q -O /forego.tgz \
        "https://bin.equinox.io/c/ekMN3bCZFUn/forego-stable-${FOREGO_ARCH}.tgz" && \
      cd /usr/local/bin && tar xfz /forego.tgz && chmod +x /usr/local/bin/forego && rm /forego.tgz && \
    # Clean container, starting with record of current size (strip / from end)
    INITIAL_SIZE="$(bash -c 'sz="$(du -sm --exclude=/proc /)" ; echo "${sz%*/}"')" && \
    #
    #
    # Perform any final cleanup actions like package manager cleaning, etc.
    yum clean all && \
    # Clean daemon-specific files
    # Let's remove easy stuff
    rm -f /usr/bin/{etcd-tester,etcd-dump-logs} && \
    # Let's compress fat binaries but keep them executable
    # As we don't run them often, the performance penalty isn't that big
    for binary in /usr/local/bin/{confd,forego,kubectl} /usr/bin/etcdctl; do \
      if [ -f "$binary" ]; then gzexe $binary && rm -f ${binary}~; fi; \
    done && \
    # Remove etcd since all we need is etcdctl
    rm -f /usr/bin/etcd && \
    # Strip binaries
    bash -c ' \
      function ifstrip () { if compgen -g "$1"; then strip -s "$1"; fi } && \
      ifstrip /usr/local/bin/{confd,forego,kubectl}' && \
    # Uncomment below line for more detailed debug info
    # find / -xdev -type f -exec du -c {} \; |sort -n && \
    echo "CLEAN DAEMON DONE!" && \
    # Clean common files like /tmp, /var/lib, etc.
    rm -rf \
        /etc/{selinux,systemd,udev} \
        /lib/{lsb,udev} \
        /tmp/* \
        /usr/lib{,64}/{locale,systemd,udev,dracut} \
        /usr/share/{doc,info,locale,man} \
        /usr/share/{bash-completion,pkgconfig/bash-completion.pc} \
        /var/log/* \
        /var/tmp/* && \
    find  / -xdev -name "*.pyc" -o -name "*.pyo" -exec rm -f {} \; && \
    # ceph-dencoder is only used for debugging, compressing it saves 10MB
    # If needed it will be decompressed
    # TODO: Is ceph-dencoder safe to remove as rook was trying to do?
    # rm -f /usr/bin/ceph-dencoder && \
    if [ -f /usr/bin/ceph-dencoder ]; then gzip -9 /usr/bin/ceph-dencoder; fi && \
    # TODO: What other ceph stuff needs removed/stripped/zipped here?
    # TODO: There was some overlap between this and the ceph clean? Where does it belong?
    #       If it's idempotent, it can *always* live here, even if it doesn't always apply
    # TODO: Should we even strip ceph libs at all?
    bash -c ' \
      function ifstrip () { if compgen -g "$1"; then strip -s "$1"; fi } && \
      ifstrip /usr/lib{,64}/ceph/erasure-code/* && \
      ifstrip /usr/lib{,64}/rados-classes/* && \
      ifstrip /usr/lib{,64}/python*/{dist,site}-packages/{rados,rbd,rgw}.*.so && \
      ifstrip /usr/bin/{crushtool,monmaptool,osdmaptool}' && \
    # Photoshop files inside a container ?
    rm -f /usr/lib/ceph/mgr/dashboard/static/AdminLTE-*/plugins/datatables/extensions/TableTools/images/psd/* && \
    # Some logfiles are not empty, there is no need to keep them
    find /var/log/ -type f -exec truncate -s 0 {} \; && \
    #
    #
    # Report size savings (strip / from end)
    FINAL_SIZE="$(bash -c 'sz="$(du -sm --exclude=/proc /)" ; echo "${sz%*/}"')" && \
    REMOVED_SIZE=$((INITIAL_SIZE - FINAL_SIZE)) && \
    echo "Cleaning process removed ${REMOVED_SIZE}MB" && \
    echo "Dropped container size from ${INITIAL_SIZE}MB to ${FINAL_SIZE}MB" && \
    #
    # Verify that the packages installed haven't been accidentally cleaned
    rpm -q \
          sharutils \
          lsof \
           \
           \
          kubernetes-client \
          etcd \
          s3cmd && echo 'Packages verified successfully'

#======================================================
# Add ceph-container files
#======================================================

# Add s3cfg file
ADD s3cfg /root/.s3cfg

# Add templates for confd
ADD ./confd/templates/* /etc/confd/templates/
ADD ./confd/conf.d/* /etc/confd/conf.d/

# Add bootstrap script, ceph defaults key/values for KV store
ADD *.sh ceph.defaults check_zombie_mons.py ./osd_scenarios/* entrypoint.sh.in disabled_scenario /

# Modify the entrypoint
RUN bash "/generate_entrypoint.sh" && \
  rm -f /generate_entrypoint.sh && \
  bash -n /*.sh


# Execute the entrypoint
WORKDIR /
ENTRYPOINT ["/entrypoint.sh"]
