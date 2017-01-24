#golang-builder

Containerized build environment for compiling an executable Golang package and packaging it in a light-weight Docker container.

## Overview

One of the (many) benefits of developing with Go is that you have the option of compiling your application into a self-contained, statically-linked binary. A statically-linked binary can be run in a container with NO other dependencies which means you can create incredibly small images.

With a statically-linked binary, you could have a Dockerfile that looks something like this:

```dockerfile
FROM scratch
COPY hello /
ENTRYPOINT ["/hello"]
```

Note that the base image here is the 0 byte *scratch* image which serves as the root layer for all Docker images. The only thing in the resulting image will be the copied binary so the total image size will be roughly the same as the binary itself.

Contrast that with using the official [golang](https://registry.hub.docker.com/u/library/golang/) image which weighs-in at 500MB before you even copy your application into it.

The *golang-builder* will accept your source code, compile it into a statically-linked binary and generate a minimal Docker image containing that binary.

Inspired by 
- https://github.com/CenturyLinkLabs/golang-builder
- http://blog.xebia.com/create-the-smallest-possible-docker-container/

## Requirements (go project setup)

In order for the golang-builder to work properly with your project, you need to follow a few simple conventions:

### Project Structure

The *golang-builder* assumes that your "main" package (the package containing your executable command) is at the root of your project directory structure.

```
.
├─Dockerfile
├─hello.go
├─hello_test.go
└─ ... other project files 
```

In the example above, the `hello.go` source file defines the "main" package for this project and lives at the root of the project directory structure. This project defines other packages ("api" and "greeting") but those are subdirectories off the root.

This convention is in place so that the *golang-builder* knows where to find the "main" package in the project structure. In a future release, we may make this a configurable option in order to support projects with different directory structures.

### Canonical Import Path

In addition to knowing where to find the "main" package, the *golang-builder* also needs to know the fully-qualified package name for your application. For the "hello" application shown above, the fully-qualified package name for the executable is "github.com/fabriziopandini/hello" but there is no way to determine that just by looking at the project directory structure (during the development, the project directory would likely be mounted at `$GOPATH/src/github.com/fabriziopandini/hello` so that the Go tools can determine the package name).

In version 1.4 of Go an annotation was introduced which allows you to identify the [canonical import path](https://golang.org/doc/go1.4#canonicalimports) as part of your source code. The annotation is a specially formatted comment that appears immediately after the `package`clause:

```go
package main // import "github.com/fabriziopandini/hello"
```

The *golang-builder* will read this annotation from your source code and use it to mount the source code into the proper place in the GOPATH for compilation.

### Dependencies

There's a good chance that your project imports at least one third-party Go package. The *golang-builder* obviously needs access to any packages that you've imported in order to compile your code. By default, *golang-builder* will `go get` any packages you've imported which aren't part of your project already.

The problem with doing a `go get` with each build is that *golang-builder* may end up with versions of packages which are different than those you developed against. Depending on the stability of the packages that you are importing this may not be an issue; in a future release, we will add support for [Godep](https://github.com/tools/godep#readme) tool.

### Dockerfile

*golang-builder* will package your compiled Go application into a Docker image automatically, then the final requirement is that your Dockerfile be placed at the root of your project directory structure. After compiling your Go application, *golang-builder* will execute a `docker build` with your Dockerfile.

The compiled binary will be placed in the root of your project directory so your Dockerfile can be written with the assumption that the application binary is in the same directory as the Dockerfile itself:

```dockerfile
FROM scratch
EXPOSE 3000
COPY hello /
ENTRYPOINT ["/hello"]
```

In this case, the *hello* binary will be copied right to the root of the image and used as the entrypoint. Since we're using the empty *scratch* image as our base, there is no need to set-up any sort of directory structure inside the image.

## Usage

There are a few things that the *golang-builder* needs in order to compile your application code and wrap it in a Docker image:

- Access to your source code. Inject your source code into the container by mounting it at the `/src` mount point with the `-v` flag.
- Access to the Docker API socket. Since the *golang-builder* code needs to interact with the Docker API in order to build the final image, you need to mount `/var/run/docker.sock` into the container with the `-v` flag when you run it. 

Assuming that the source code for your Go executable package is located at`/home/go/src/github.com/fabriziopandini/hello` on your local system and you're currently in the `hello` directory, you'd run the `golang-builder` container as follows:

```bash
docker run --rm \
  -v "$(pwd):/src" \
  -v /var/run/docker.sock:/var/run/docker.sock \
  fabriziopandini/golang-builder
```

This would result in the creation of a new Docker image named `hello:latest`.

Note that the image tag is generated dynamically from the name of the Go package. If you'd like to specify an image tag name you can provide it as an argument after the image name.

```bash
docker run --rm \
  -v "$(pwd):/src" \
  -v /var/run/docker.sock:/var/run/docker.sock \
  fabriziopandini/golang-builder \
  fabriziopandini/hello:1.0
```

### Additional Options

- CGO_ENABLED - whether or not to compile the binary with CGO (defaults to false)
- LDFLAGS - flags to pass to the linker (defaults to '-s')
- OUTPUT - if set, will use the `-o` option with `go build` to output the final binary to the value of this env var
- DOCKERFILE - if set, will use the `-f` option with `docker build` and use the Dockerfile that correspond to the value of this env var

The above are environment variables to be passed to the docker run command:

```bash
docker run --rm \
  -e CGO_ENABLED=true \
  -e LDFLAGS='-extldflags "-static"' \
  -e COMPRESS_BINARY=true \
  -e OUTPUT=/bin/my_go_binary \
  -e DOCKERFILE=myDockerFile \
  -v $(pwd):/src \
  fabriziopandini/golang-builder
```

### Makefile

A makefile will help in making your development pipeline simpler and straight forward:

```
NAME = fabriziopandini/hello
VERSION = 0.1

all: package

#..other targets for testing your app locally e.g. build, test

package:
	docker run --rm -v $(PWD):/src -v /var/run/docker.sock:/var/run/docker.sock fabriziopandini/golang-builder $(NAME):$(VERSION)

test_package: 
	docker run --rm $(NAME):$(VERSION)

tag: 
	docker tag $(NAME):$(VERSION) $(NAME):latest
    
push: 
	docker push $(NAME)
```



## Cross-compilation

in a future release, we will add support for cross compilation.
