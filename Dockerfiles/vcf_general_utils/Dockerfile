FROM ubuntu:20.04
LABEL maintainer="Miguel Brown (brownm28@email.chop.edu)"

ENV DEBIAN_FRONTEND=noninteractive

RUN apt update && apt install -y wget samtools bcftools vcftools tabix bedtools build-essential zlib1g zlib1g-dev python3-pip \
&& wget https://downloads.python.org/pypy/pypy3.8-v7.3.9-linux64.tar.bz2 \
&& tar -xjf pypy3.8-v7.3.9-linux64.tar.bz2 && rm pypy3.8-v7.3.9-linux64.tar.bz2 \
&& python3 -m pip install bgzip \
&& apt remove -y wget && apt autoclean -y && apt autoremove -y

ADD Dockerfile ./