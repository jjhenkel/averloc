FROM tensorflow/tensorflow:1.15.0-gpu-py3

RUN apt-get install -y nvidia-modprobe

RUN pip3 install requests

ENV NVIDIA_VISIBLE_DEVICES all
ENV NVIDIA_DRIVER_CAPABILITIES compute,utility

COPY vendor/code2seq /code2seq
<<<<<<< HEAD
COPY task/ /app/

ENTRYPOINT [ "/app/entrypoint.sh" ]
=======
COPY task/entrypoint.sh /entrypoint.sh

ENTRYPOINT [ "/entrypoint.sh" ]
>>>>>>> 456449a5524071af4774e6f0817a0650f3d7bc08
