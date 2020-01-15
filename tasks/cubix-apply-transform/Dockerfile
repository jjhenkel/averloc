# Grabbed this from the Cubix artifact because it wasn't on Github...
FROM ubuntu:18.04

RUN apt-get update && \
  apt-get install -y  \
    m4 git vim make ssh unicode unicode-data dpkg-dev libncurses5-dev pax-utils \
    ruby libc6-dev haskell-stack netbase lua5.3 openjdk-8-jdk python gcc-6 ca-certificates nodejs

RUN apt-get update && apt-get install happy alex && stack upgrade && cp /root/.local/bin/stack /usr/bin/

WORKDIR /cubix

ADD vendor/cubix /cubix/cubix

RUN apt-get update && apt-get install -y jq

RUN cd /cubix/cubix && stack build --ghc-options='-O0 -j +RTS -A256m -n2m -RTS'

COPY task/entrypoint.sh /entrypoint.sh

ENTRYPOINT [ "/entrypoint.sh" ]
