FROM python:3.7

RUN pip3 install --no-cache click asttokens

COPY app.py /app/app.py

ENTRYPOINT [ "python3", "/app/app.py" ]
