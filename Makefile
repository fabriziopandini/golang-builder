# https://github.com/phusion/baseimage-docker/blob/master/Makefile
NAME = fabriziopandini/golang-builder
VERSION = 0.2

all: build

build:
	@docker build --rm -t $(NAME):$(VERSION) --build-arg http_proxy=$(http_proxy) --build-arg https_proxy=$(https_proxy) .

tag: 
	@docker tag $(NAME):$(VERSION) $(NAME):latest
    
push: 
	@docker push $(NAME)

