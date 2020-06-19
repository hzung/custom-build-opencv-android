FROM ubuntu:18.04

RUN apt update && apt install -y \
						vim \
						openjdk-8-jdk \
						python2.7 \
						python-pip \
						ninja-build \
						ant \
						lib32stdc++6 \
						lib32z1 \
            wget

RUN wget https://cmake.org/files/v3.7/cmake-3.7.2-Linux-x86_64.sh -O /cmake-3.7.2-Linux-x86_64.sh \
    && mkdir /opt/cmake \
    && sh /cmake-3.7.2-Linux-x86_64.sh --prefix=/opt/cmake --skip-license \
    && ln -s /opt/cmake/bin/cmake /usr/local/bin/cmake \
    && cmake --version \
    && rm -rf /usr/lib/jvm/java*11* \
    && rm /usr/bin/java \
    && ln -s /usr/lib/jvm/java-1.8.0-openjdk-amd64/bin/java /usr/bin/java

COPY ./env_var_setup /root/env_var_setup
RUN echo 'source /root/env_var_setup' >> /root/.bashrc