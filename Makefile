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
	 -t package.eisoo.com:8082/eisoo/ceph:${TAG} .
	@touch cephdaemon

cephnginx:
	docker build -t package.eisoo.com:8082/eisoo/nginx:ceph --file=Dockerfile.nginx .
	@touch cephnginx

clean:
	@rm -f cephbase cephdaemon cephnginx
	docker rmi eisoo/ceph-base:${TAG}
	docker rmi package.eisoo.com:8082/eisoo/ceph:${TAG}
	docker rmi package.eisoo.com:8082/eisoo/nginx:ceph

