FROM openjdk:8

RUN apt-get update && apt-get install -y jq

WORKDIR /app

RUN mkdir /mnt/outputs-raw

COPY task/ /app/

RUN \
  javac -cp /app/spoon.jar transforms/AddDeadCodeAtBeginning.java && \
  javac -cp /app/spoon.jar transforms/RenameLocalVariable.java && \
  javac -cp /app/spoon.jar Transforms.java

ENTRYPOINT [ "/app/entrypoint.sh" ]
