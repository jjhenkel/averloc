FROM openjdk:8

RUN apt-get update && apt-get install -y --no-install-recommends g++

WORKDIR /astminer

COPY vendor/astminer/ /astminer/

RUN /astminer/gradlew processMyExample || return 0

# Setup entrypoint into the analysis code logic
CMD [ "/astminer/gradlew", "processMyExample" ]
