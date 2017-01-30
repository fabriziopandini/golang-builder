# https://github.com/phusion/baseimage-docker/blob/master/Makefile
NAME = fabriziopandini/golang-builder
VERSION = 0.2

all: build

build:
	@docker build --rm -t $(NAME):$(VERSION) .

tag: 
	@docker tag $(NAME):$(VERSION) $(NAME):latest 
    
push: 
	@docker push $(NAME)

rmi: 
	@docker rmi $(NAME) $(NAME):$(VERSION)