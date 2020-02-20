## reference: https://github.com/asciinema/asciinema/blob/develop/Dockerfile; https://linuxize.com/post/how-to-install-r-on-ubuntu-18-04/ 
## -*- mode: sh; -*-

FROM ubuntu:18.04

RUN apt-get update && apt-get install -y \
    ca-certificates \
    locales \
    python3 \
    python3-setuptools
RUN localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8
RUN mkdir /usr/src/app
COPY setup.cfg /usr/src/app
COPY setup.py /usr/src/app
COPY *.md /usr/src/app/
COPY doc/*.md /usr/src/app/doc/
COPY man/asciinema.1 /usr/src/app/man/
COPY asciinema /usr/src/app/asciinema
WORKDIR /usr/src/app
RUN python3 setup.py install
ENV LANG en_US.utf8
ENV SHELL /bin/bash
ENV USER docker
WORKDIR /root

# Install R-3.6

RUN apt install apt-transport-https software-properties-common
RUN apt-key adv --keyserver keyserver.ubuntu.com --recv-keys E298A3A825C0D65DFD57CBB651716619E084DAB9
RUN add-apt-repository 'deb https://cloud.r-project.org/bin/linux/ubuntu bionic-cran35/'
RUN apt update
RUN apt install -yq r-base
