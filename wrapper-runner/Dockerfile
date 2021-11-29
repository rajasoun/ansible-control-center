FROM cytopia/ansible:latest-tools

RUN set -ex \
    &&  apk add --no-cache --update \
        gcc libffi-dev openssl-dev musl-dev linux-headers  python3-dev py3-pip curl\
    && pip3 install --upgrade --no-cache-dir \
        pip setuptools python-openstackclient awscli \
    && curl https://raw.githubusercontent.com/wallix/awless/master/getawless.sh | bash \
    && apk del gcc musl-dev linux-headers libffi-dev \
    &&  rm -rf /tmp/* \
    &&  rm -rf /var/tmp/* \
    &&  rm -rf /var/cache/apk/* 

