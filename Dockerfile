FROM ubuntu:latest

EXPOSE 9699
EXPOSE 9755
EXPOSE 9647

ENV keys="generate"
ENV harvester="false"
ENV farmer="false"
ENV plots_dir="/plots"
ENV farmer_address="null"
ENV farmer_port="null"
ENV testnet="false"
ENV full_node_port="null"
ENV TZ="UTC"
ARG BRANCH

RUN DEBIAN_FRONTEND=noninteractive apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y curl jq python3 ansible tar bash ca-certificates git openssl unzip wget python3-pip sudo acl build-essential python3-dev python3.8-venv python3.8-distutils apt nfs-common python-is-python3 vim tzdata

RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone
RUN dpkg-reconfigure -f noninteractive tzdata

RUN echo "cloning main"
RUN git clone --branch main https://github.com/HiveProject2021/chives-blockchain.git \
&& cd chives-blockchain \
&& git submodule update --init mozilla-ca \
&& sed -i s/9699/8444/g chives/wallet/derive_keys.py \
&& chmod +x install.sh \
&& /usr/bin/sh ./install.sh

ENV PATH=/chives-blockchain/venv/bin/:$PATH
WORKDIR /chives-blockchain
ADD ./entrypoint.sh entrypoint.sh

ENTRYPOINT ["bash", "./entrypoint.sh"]
