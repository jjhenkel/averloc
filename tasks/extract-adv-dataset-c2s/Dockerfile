FROM python:3.7-stretch

RUN pip install tqdm

COPY models/code2seq /model

COPY task/ /app/

ENTRYPOINT [ "/app/entrypoint.sh" ]
