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

RUN apt install -y apt-transport-https software-properties-common
RUN apt-key adv --keyserver keyserver.ubuntu.com --recv-keys E298A3A825C0D65DFD57CBB651716619E084DAB9
RUN add-apt-repository 'deb https://cloud.r-project.org/bin/linux/ubuntu bionic-cran35/'
RUN apt update
RUN apt install -yq r-base

# Install Bioconductor

# nuke cache dirs before installing pkgs; tip from Dirk E fixes broken img
RUN rm -f /var/lib/dpkg/available && rm -rf  /var/cache/apt/*

# issues with '/var/lib/dpkg/available' not found
# this will recreate
RUN dpkg --clear-avail

# This is to avoid the error
# 'debconf: unable to initialize frontend: Dialog'
ENV DEBIAN_FRONTEND noninteractive

# Update apt-get
RUN apt-get update \
    && apt-get install -y --no-install-recommends apt-utils \
    && apt-get install -y --no-install-recommends \
    ## Basic deps
    gdb \
    libxml2-dev \
    python-pip \
    libz-dev \
    liblzma-dev \
    libbz2-dev \
    libpng-dev \
    libmariadb-dev-compat \
    ## sys deps from bioc_full
    pkg-config \
    fortran77-compiler \
    byacc \
    automake \
    curl \
    ## This section installs libraries
    libpng-dev \
    libnetcdf-dev \
    libhdf5-serial-dev \
    libfftw3-dev \
    libopenbabel-dev \
    libopenmpi-dev \
    libexempi8 \
    libxt-dev \
    libgdal-dev \
    libjpeg62-turbo-dev \
    libcairo2-dev \
    libtiff5-dev \
    libreadline-dev \
    libgsl0-dev \
    libgslcblas0 \
    libgtk2.0-dev \
    libgl1-mesa-dev \
    libglu1-mesa-dev \
    libgmp3-dev \
    libhdf5-dev \
    libncurses-dev \
    libbz2-dev \
    libxpm-dev \
    liblapack-dev \
    libv8-dev \
    libgtkmm-2.4-dev \
    libmpfr-dev \
    libudunits2-dev \
    libmodule-build-perl \
    libapparmor-dev \
    libgeos-dev \
    libprotoc-dev \
    librdf0-dev \
    libmagick++-dev \
    libsasl2-dev \
    libpoppler-cpp-dev \
    libprotobuf-dev \
    libpq-dev \
    libperl-dev \
    ## software - perl extentions and modules
    libarchive-extract-perl \
    libfile-copy-recursive-perl \
    libcgi-pm-perl \
    libdbi-perl \
    libdbd-mysql-perl \
    libxml-simple-perl \
    ## Databases and other software
    sqlite \
    openmpi-bin \
    mpi-default-bin \
    openmpi-common \
    openmpi-doc \
    tcl8.6-dev \
    tk-dev \
    default-jdk \
    imagemagick \
    tabix \
    ggobi \
    graphviz \
    protobuf-compiler \
    jags \
    ## Additional resources
    xfonts-100dpi \
    xfonts-75dpi \
    biber \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

## Python installations
RUN apt-get update \
    && apt-get -y --no-install-recommends install python-dev \
    && pip install wheel \
    ## Install sklearn and pandas on python
    && pip install sklearn \
    pandas \
    pyyaml \
    cwltool \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install libsbml and xvfb
RUN cd /tmp \
    ## libsbml
    && curl -O https://s3.amazonaws.com/linux-provisioning/libSBML-5.10.2-core-src.tar.gz \
    && tar zxf libSBML-5.10.2-core-src.tar.gz \
    && cd libsbml-5.10.2 \
    && ./configure --enable-layout \
    && make \
    && make install \
    ## xvfb install
    && cd /tmp \
    && curl -SL https://github.com/just-containers/s6-overlay/releases/download/v1.21.8.0/s6-overlay-amd64.tar.gz | tar -xzC / \
    && apt-get update && apt-get install -y --no-install-recommends xvfb \
    && mkdir -p /etc/services.d/xvfb/ \
    ## Clean libsbml, and tar.gz files
    && rm -rf /tmp/libsbml-5.10.2 \
    && rm -rf /tmp/libSBML-5.10.2-core-src.tar.gz \
    ## apt-get clean and remove cache
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

COPY ./deps/xvfb_init /etc/services.d/xvfb/run

RUN echo "R_LIBS=/usr/local/lib/R/host-site-library:\${R_LIBS}" > /usr/local/lib/R/etc/Renviron.site \
    && echo "options(defaultPackages=c(getOption('defaultPackages'),'BiocManager'))" >> /usr/local/lib/R/etc/Rprofile.site

ADD install.R /tmp/

RUN R -f /tmp/install.R

## DEVEL: Add sys env variables to DEVEL image
RUN curl -O https://raw.githubusercontent.com/Bioconductor/BBS/master/3.11/R_env_vars.sh \
    && cat R_env_vars.sh | grep -o '^[^#]*' | sed 's/export //g' >>/etc/environment \
    && cat R_env_vars.sh >> /root/.bashrc \
    && rm -rf R_env_vars.sh
