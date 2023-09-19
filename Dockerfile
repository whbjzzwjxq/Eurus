ARG UBUNTU_NAME=jammy
ARG UBUNTU_VERSION=22.04
FROM ubuntu:$UBUNTU_VERSION as dev
WORKDIR /Eurus

ARG PYTHON_VERSION=3.11

RUN apt-get update && \
    apt-get --yes install --no-install-recommends \
    git \
    python${PYTHON_VERSION} \
    python-is-python3 \
    python3-pip \
    nodejs \
    npm \
    curl \
    vim

COPY ./requirements.txt /Eurus/requirements.txt

RUN pip3 install -q --upgrade pip && \
    pip3 install -q -r ./requirements.txt

RUN solc-select install 0.8.15 && \
    solc-select use 0.8.15

COPY ./package.json /Eurus/package.json

RUN npm install --quiet --save-dev

RUN curl -L https://foundry.paradigm.xyz | bash
ENV PATH="$PATH:/root/.foundry/bin"
RUN foundryup
# RUN ["/bin/bash", "-c", "source /root/.bashrc"]
# RUN ["/bin/bash", "-c", "foundryup"]

COPY . /Eurus
