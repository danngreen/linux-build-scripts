FROM ubuntu:22.04
ENV DEBIAN_FRONTEND="noninteractive"
RUN apt update
RUN apt install -y git rsync gcc g++ make device-tree-compiler bc flex bison lz4 libssl-dev libgmp-dev libmpc-dev expect expect-dev file unzip bzip2 fakeroot bsdmainutils
RUN apt install -y python2 python3 python-is-python3 wget xxd libncurses-dev cpio xz-utils python3-setuptools
RUN apt-get install -y sudo bash-completion
RUN useradd -m worker -s /bin/bash  
RUN echo "export TERM=xterm-256color" >> /home/worker/.bashrc
RUN wget https://developer.arm.com/-/media/Files/downloads/gnu/14.2.rel1/binrel/arm-gnu-toolchain-14.2.rel1-x86_64-arm-none-linux-gnueabihf.tar.xz -O gcc-aarch64-none-linux-gnu.tar.xz
RUN mkdir gcc-aarch64-none-linux-gnu && unxz gcc-aarch64-none-linux-gnu.tar.xz
RUN tar xf gcc-aarch64-none-linux-gnu.tar -C gcc-aarch64-none-linux-gnu --strip-components 1
RUN rm gcc-aarch64-none-linux-gnu.tar
ENV PATH="/gcc-aarch64-none-linux-gnu/bin:${PATH}"

RUN apt install -y swig python3-dev uuid-dev
RUN apt install -y libgnutls28-dev
USER worker
WORKDIR /project
ENV CROSS_COMPILE=/gcc-aarch64-none-linux-gnu/bin/arm-none-linux-gnueabihf-
