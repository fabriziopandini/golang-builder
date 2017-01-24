# https://github.com/phusion/baseimage-docker/blob/master/Makefile
NAME = fabriziopandini/golang-builder
VERSION = 0.1

all: build

build:
	docker build --rm -t $(NAME):$(VERSION) --build-arg http_proxy=$(http_proxy) --build-arg https_proxy=$(https_proxy) .

tag: build
	docker tag $(NAME):$(VERSION) $(NAME):latest
    
push: tag
	docker push $(NAME)

