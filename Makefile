name=trivy
localName=localhost/$(name)
dockerName=docker.io/akiraheid/$(name)
saveName=$(name).tar
cacheDir=${HOME}/containers/trivy/.cache

.PHONY: image scan tags version
.DEFAULT: image

clean:
	-rm -r image VERSION

image:
	podman pull docker.io/aquasec/trivy:latest
	podman build -t localhost/$(name) .

release: version
	podman tag $(localName):latest $(dockerName):`head -n 1 VERSION` \
		&& podman push $(dockerName):`head -n 1 VERSION` \
		&& podman tag $(localName):latest $(dockerName):`head -n 2 VERSION | tail -n 1` \
		&& podman push $(dockerName):`head -n 2 VERSION | tail -n 1` \
		&& podman tag $(localName):latest $(dockerName):`head -n 3 VERSION | tail -n 1` \
		&& podman push $(dockerName):`head -n 3 VERSION | tail -n 1` \
		&& podman tag $(localName):latest $(dockerName):latest \
		&& podman push $(dockerName):latest

scan: clean image
	-mkdir -p $(cacheDir) image
	podman save -o image/$(saveName) localhost/$(name):latest
	podman run --rm -it \
		-v ${PWD}/image/:/image/:rw \
		-v $(cacheDir)/:/root/.cache/:rw \
		localhost/$(name):latest image --input /image/$(saveName)

tags: version
	podman tag $(localName):latest $(localName):`head -n 1 VERSION` \
		&& podman tag $(localName):latest $(localName):`head -n 2 VERSION | tail -n 1` \
		&& podman tag $(localName):latest $(localName):`head -n 3 VERSION | tail -n 1`

version:
	VER=`podman run --rm $(localName):latest --version | cut -d ' ' -f 2` \
		&& MAJOR=`echo $$VER | cut -d . -f 1` \
		&& MINOR=`echo $$VER | cut -d . -f 2` \
		&& PATCH=`echo $$VER | cut -d . -f 3` \
		&& echo $$MAJOR > VERSION \
		&& echo $$MAJOR.$$MINOR >> VERSION \
		&& echo $$MAJOR.$$MINOR.$$PATCH >> VERSION
