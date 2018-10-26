all: cephbase cephdaemon cephnginx

cephbase:
	docker build -t eisoo/ceph-base:${TAG} .
	@touch cephbase

cephdaemon:
	cd daemon && docker build \
	 --network host \
	 --build-arg http_proxy=192.168.56.81:3128 \
	 --build-arg https_proxy=192.168.56.81:3128 \
	 --build-arg ftp_proxy=192.168.56.81:3128 \
	 --build-arg no_proxy=192.168.*.*,localhost,127.0.0.1 \
	 --build-arg baseimage=eisoo/ceph-base:${TAG} \
	 -t maxthwell/ceph:${TAG} \
	 -t eisoo/ceph:${TAG} \
	 -t package.eisoo.com:8082/eisoo/ceph:${TAG} \
	 -t package.eisoo.com:8084/eisoo/ceph:${TAG} .
	@touch cephdaemon

cephnginx:
	docker build \
	 -t maxthwell/ceph-nginx:${TAG} \
	 -t eisoo/ceph-nginx:${TAG} \
	 -t package.eisoo.com:8082/eisoo/ceph-nginx:${TAG} \
	 -t package.eisoo.com:8084/eisoo/ceph-nginx:${TAG} \
	 --file=Dockerfile.nginx .
	@touch cephnginx

clean:
	@rm -f cephbase cephdaemon cephnginx
	docker rmi eisoo/ceph-base:${TAG}
	docker rmi maxthwell/ceph:${TAG}
	docker rmi eisoo/ceph:${TAG}
	docker rmi package.eisoo.com:8082/eisoo/ceph:${TAG}
	docker rmi package.eisoo.com:8084/eisoo/ceph:${TAG}
	docker rmi maxthwell/ceph-nginx:${TAG}
	docker rmi eisoo/ceph-nginx:${TAG}
	docker rmi package.eisoo.com:8082/eisoo/ceph-nginx:${TAG}
	docker rmi package.eisoo.com:8084/eisoo/ceph-nginx:${TAG}

