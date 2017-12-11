FROM ubuntu:trusty

ENV DEBIAN_FRONTEND noninteractive
ENV PATH $PATH:/usr/local/nginx/sbin
ENV NGINX_VERSION 1.21.1
ENV RTMP_SOURCE https://github.com/ut0mt8/nginx-rtmp-module
ENV RTMP_VERSION 1.2.0
ENV RTMP_SHA512SUM 16325ab70ff3e741b2c903fd644d98e23a3790eabe787bb27ea7558c0f038cac86cd1e89e51fc597883dcf89a2f875768c673eeec9a6969a6f380c3013a7fc65

EXPOSE 1935
EXPOSE 80

# create directories
RUN mkdir /src /config /logs /data /static

# update and upgrade packages
RUN apt-get update && \
  apt-get upgrade -y && \
  apt-get clean && \
  apt-get install -y --no-install-recommends build-essential \
  wget software-properties-common && \
# ffmpeg
  add-apt-repository ppa:mc3man/trusty-media && \
  apt-get update && \
  apt-get install -y --no-install-recommends ffmpeg && \
# nginx dependencies
  apt-get install -y --no-install-recommends libpcre3-dev \
  zlib1g-dev libssl-dev wget && \
  rm -rf /var/lib/apt/lists/*

# get nginx source
WORKDIR /src
RUN wget http://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz && \
  wget http://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz.asc && \
  gpg --keyserver pgp.mit.edu --recv a1c052f8 && \
  gpg -v nginx-${NGINX_VERSION}.tar.gz.asc && \
  tar zxf nginx-${NGINX_VERSION}.tar.gz && \
  rm -f nginx-${NGINX_VERSION}.tar.gz nginx-${NGINX_VERSION}.tar.gz.asc && \
# get nginx-rtmp module
  wget ${RTMP_SOURCE}/archive/v${RTMP_VERSION}.tar.gz && \
  echo "${RTMP_SHA512SUM}  v${RTMP_VERSION}.tar.gz" | sha512sum --quiet -c && \
  tar zxf v${RTMP_VERSION}.tar.gz && \
  rm -f v${RTMP_VERSION}.tar.gz

# compile nginx
WORKDIR /src/nginx-${NGINX_VERSION}
RUN ./configure --add-module=/src/nginx-rtmp-module-${RTMP_VERSION} \
  --conf-path=/config/nginx.conf \
  --error-log-path=/logs/error.log \
  --http-log-path=/logs/access.log && \
  make && \
  make install

ADD nginx.conf /config/nginx.conf
ADD static /static

WORKDIR /
CMD "nginx"
