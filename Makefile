all: base ceph

base:
	docker build -t maxthwell/ceph-base:${TAG} .
	@touch base

ceph:
	cd daemon && docker build --build-arg baseimage=maxthwell/ceph-base:${TAG} -t maxthwell/ceph:${TAG} .
	@touch ceph

clean:
	@rm -f ceph base
	docker rmi maxthwell/ceph-base:${TAG}
	docker rmi maxthwell/ceph:${TAG}

