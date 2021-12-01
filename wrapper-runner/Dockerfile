FROM cytopia/ansible:latest-tools

RUN set -ex \
    &&  apk add --no-cache --update \
        gcc libffi-dev openssl-dev musl-dev \
        linux-headers python3-dev py3-pip  curl \
    && pip3 install --upgrade --no-cache-dir \
        pip setuptools python-openstackclient awscli \
    && apk del gcc musl-dev linux-headers libffi-dev \
    &&  rm -rf /tmp/* \
    &&  rm -rf /var/tmp/* \
    &&  rm -rf /var/cache/apk/* 


RUN set -ex \
    &&  curl -LO https://repo-art.cisco.com/artifactory/codectl/stable/latest/codectl-linux-amd64 \
    &&  install codectl-linux-amd64 /usr/local/bin/codectl


