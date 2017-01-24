FROM golang:latest
MAINTAINER Fabrizio Pandini <fabrizio.pandini@gmail.com>

ARG DOCKER_VERSION=1.13.0

# Install Docker binary (see https://github.com/docker/docker/releases)
RUN wget -q https://get.docker.com/builds/Linux/x86_64/docker-${DOCKER_VERSION}.tgz  && \
  tar xzf docker-${DOCKER_VERSION}.tgz && \
  mv docker/* /usr/bin/ && \
  chmod +x /usr/bin/docker && \
  rm -r docker*

VOLUME /src
WORKDIR /src

#COPY build_environment.sh /
COPY build.sh /

ENTRYPOINT ["/build.sh"]