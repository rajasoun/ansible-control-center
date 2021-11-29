FROM cytopia/ansible:latest-tools

RUN set -ex \
    &&  apk add --no-cache --update \
        gcc libffi-dev openssl-dev musl-dev \
        linux-headers python3-dev py3-pip  \
    && pip3 install --upgrade --no-cache-dir \
        pip setuptools python-openstackclient awscli \
    && apk del gcc musl-dev linux-headers libffi-dev \
    &&  rm -rf /tmp/* \
    &&  rm -rf /var/tmp/* \
    &&  rm -rf /var/cache/apk/* 



