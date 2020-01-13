FROM openjdk:8

RUN apt-get update && apt-get install -y jq parallel

WORKDIR /app

RUN mkdir /mnt/outputs-raw

COPY task/ /app/

RUN \
  javac -cp /app/spoon.jar:/app/gson.jar:/app transforms/*.java && \
  javac -cp /app/spoon.jar:/app/gson.jar:/app Transforms.java

ENTRYPOINT [ "/app/entrypoint.sh" ]
