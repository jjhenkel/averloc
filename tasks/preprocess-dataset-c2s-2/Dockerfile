FROM python:3.7-stretch

RUN pip3 install numpy tensorflow

COPY task/entrypoint.sh /entrypoint.sh

COPY vendor/code2seq /code2seq

ENTRYPOINT [ "/entrypoint.sh" ]
