FROM ubuntu:20.04
MAINTAINER bewoayia.keianyor@dlr.de

ARG DEBIAN_FRONTEND=noninteractive

USER root

# Install LLVM-Toolchain dependencies. Comment this out if a pre-built version of riscv-gnu-toolchain is used
RUN apt-get update && apt-get -y install gnupg software-properties-common build-essential g++ git apt-utils gawk cmake texinfo expat zlib1g-dev flex bison clang python3-dev lld bash diffutils python3-psutil python3-distutils wget sudo && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

#Install Riscv-gnu-toolchain dependencies
RUN apt-get update && \
    apt-get install -y autoconf automake autotools-dev curl python3 python3-pip python3-venv libmpc-dev libmpfr-dev libgmp-dev gawk build-essential bison flex texinfo gperf libtool patchutils bc zlib1g-dev libexpat-dev cmake gdb && \
	apt-get clean && rm -rf /var/lib/apt/lists/*

ENV RISCV_GNU_TOOLCHAIN /opt/gcc-riscv
RUN sudo mkdir $RISCV_GNU_TOOLCHAIN  && sudo touch $RISCV_GNU_TOOLCHAIN/install.stamp

WORKDIR /opt/builder

# install and build Riscv-gnu-toolchain
# !!!!!!!! COMMENT THIS SECTION OUT IF CLONING "https://github.com/riscv/riscv-gnu-toolchain" FAILS DUE TO IT-CONFIGURATION RESCTRICTIONS !!!!! -- USE INSTEAD DELIVERED TAR BALL - extract into /opt/gcc-riscv/. This location will be mounted and from the host file system and used within the container !!!!!!!!!!!!!!!!!!!!!!!!!
RUN git clone --recursive https://github.com/riscv/riscv-gnu-toolchain && \
  cd riscv-gnu-toolchain && \
    ./configure --prefix=$RISCV_GNU_TOOLCHAIN --without-system-zlib --enable-multilib --with-arch=rv32gc --with-abi=ilp32d && \
  make -j`nproc` newlib && \
  cd .. && \
  rm -rf riscv-gnu-toolchain
    
COPY [ "entrypoint.sh", "/opt/" ]

RUN chmod a+rwx /opt/entrypoint.sh

ENTRYPOINT ["/opt/entrypoint.sh"]
