# Grabbed this from the Cubix artifact because it wasn't on Github...
FROM ubuntu:18.04

RUN apt-get update
RUN apt-get install -y --no-install-recommends m4=1.4.18-1 git=1:2.17.1-1ubuntu0.1 vim=2:8.0.1453-1ubuntu1 make=4.1-9.1ubuntu1 ssh=1:7.6p1-4 unicode=2.4 unicode-data=10.0.0-3 dpkg-dev=1.19.0.5ubuntu2 libncurses5-dev=6.1-1ubuntu1.18.04 pax-utils=1.2.2-1

# For some reason, stack upgrade installs to a different directory than either the Ubuntu package or the normal install script
RUN apt-get install -y --no-install-recommends ruby=1:2.5.1 libc6-dev=2.27-3ubuntu1 haskell-stack=1.5.1-1 netbase=5.4 && stack upgrade && cp /root/.local/bin/stack /usr/bin/

# Language versions
RUN apt-get install -y --no-install-recommends lua5.3=5.3.3-1 openjdk-8-jdk=8u181-b13-0ubuntu0.18.04.1 python=2.7.15~rc1-1 gcc-6=6.4.0-17ubuntu1

## Copy the host system's benchmark code

# We intentionally delayed the addition of the working directory upto
# this point: whenever the directory state changes on the host system,
# we get a cache miss and every step after this one has to be replayed
# when rebuilding the Docker image. On the other hand,
# environment-setting commands above remain cached.
WORKDIR /cubix
ADD node-v0.10.30-linux-x64 /node
RUN echo 'export PATH=$PATH:/node/bin/' >> /root/.bashrc
ADD language_tests /cubix/language_tests
ADD getting_started.md /cubix
ADD step-by-step-instructions.md /cubix

# Note: "ADD cubix /cubix/cubix" may copy over the Docker
# container some build artefacts coming from the host's repository (if
# it was used for testing and not in a clean state). The 'stack clean'
# run above makes sure we start from a clean state.

# C tests
RUN cd /cubix/language_tests && git clone https://github.com/gcc-mirror/gcc.git && cd gcc && git reset --hard f72de674726c5d054b9d99b0a4db09dfb52bf494
# Didn't get this building; using system GCC instead
#RUN cd /cubix/language_tests && mkdir gcc_build && cd gcc_build && ../gcc/configure && make -j8 && make install

# Java tests
RUN cd /cubix/language_tests && git clone https://github.com/kframework/java-semantics && cd java-semantics && git reset --hard c202266304340a2a4be81fa21ee4fe36b3117ee3

# JS tests
RUN cd /cubix/language_tests && git clone https://github.com/kframework/javascript-semantics.git && cd javascript-semantics && git reset --hard d5aca308d12d3838c645e1f787e2abc9257ce43e && make test262

#Python tests
RUN cd /cubix/language_tests && git clone https://github.com/python/cpython.git && cd cpython && git reset --hard 7bd4afec86849a57b48f375a9c4e0c32f0539dad
RUN cd /cubix/language_tests/cpython && ./configure && make

RUN apt-get install -y --no-install-recommends zsh=5.4.2-3ubuntu3

ADD cubix /cubix/cubix

RUN cd /cubix/cubix/languages && stack build --ghc-options='-O0 -j +RTS -A256m -n2m -RTS'
