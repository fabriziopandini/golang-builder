FROM golang
MAINTAINER Fabrizio Pandini <fabrizio.pandini@gmail.com>

ARG DOCKER_VERSION=17.04.0-ce

# Install Docker binary (see https://github.com/docker/docker/releases)
RUN wget -q https://get.docker.com/builds/Linux/x86_64/docker-${DOCKER_VERSION}.tgz  && \
  tar xzf docker-${DOCKER_VERSION}.tgz && \
  mv docker/* /usr/bin/ && \
  chmod +x /usr/bin/docker && \
  rm -r docker*

VOLUME /src
WORKDIR /src

COPY build.sh /

ENTRYPOINT ["/build.sh"]