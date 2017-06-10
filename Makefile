# https://github.com/phusion/baseimage-docker/blob/master/Makefile
NAME = fabriziopandini/golang-builder

all: build

build:
	@docker build --rm -t $(NAME) .

rmi: 
	@docker rmi $(NAME)