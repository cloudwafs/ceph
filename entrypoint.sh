#!/bin/sh

case $1 in
	osd|mon)
	/usr/bin/ceph-$1 -f --cluster ceph --id $2 --setuser root --setgroup root --pid-file /var/run/ceph/$1.$2.pid
	;;
	rgw)
	/usr/bin/radosgw -f --cluster ceph --name client.radosgw.ceph-node$2 --setuser root --setgroup root
	;;
	*)
	echo "first arg must in (osd | mon | rgw) and second arg must be unsigned integer"
	;;
esac
