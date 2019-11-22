FROM debian:stretch

RUN apt-get update && apt-get install -y --no-install-recommends parallel jq zip curl ca-certificates

COPY task/entrypoint.sh task/bin/jq /

ENTRYPOINT [ "/entrypoint.sh" ]
