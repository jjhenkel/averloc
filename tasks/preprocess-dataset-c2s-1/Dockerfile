FROM openjdk:8

RUN apt-get update && apt-get install -y --no-install-recommends g++

WORKDIR /astminer

COPY vendor/astminer/ /astminer/

RUN /astminer/gradlew processMyExample || return 0

COPY task/entrypoint.sh /entrypoint.sh

ENTRYPOINT [ "/entrypoint.sh" ]
