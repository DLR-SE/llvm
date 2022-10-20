#!/bin/bash

#1. First build the image to be used for instantiating containers 
docker build -t s4e-llvm-builder . 

#2. Crreate a container from the s4e-llvm-image and clone the extensible-compiler from DLR Git Repository
# Note that the location for cloning the compiler are mount volumes 
docker run --rm --name=S4E-Container -it -v /var/lib/docker/volumes/s4e_src/_data/:/home/s4e-builder/src/ -v /var/lib/docker/volumes/s4e_build/_data/:/home/s4e-builder/build -v /var/lib/docker/volumes/s4e_install/_data/:/home/s4e-builder/install/ s4e-llvm-builder s4e-builder 2001 b_scale4edge update


#3. Create a container from the s4e-llvm-builder image and build the extensible-compiler cloned under /home/s4e-builder/src
# This step will build the extensible compiler and a runtime using the gcc-toolchain
docker run --rm --name=S4E-Container -it -v /var/lib/docker/volumes/s4e_src/_data/:/home/s4e-builder/src/ -v /var/lib/docker/volumes/s4e_build/_data/:/home/s4e-builder/build -v /var/lib/docker/volumes/s4e_install/_data/:/home/s4e-builder/install/ s4e-llvm-builder s4e-builder 2001 b_scale4edge build


#4. # This step creates a container and execute the regression test for LLVM within the created container
docker run --rm --name=S4E-Container -it -v /var/lib/docker/volumes/s4e_src/_data/:/home/s4e-builder/src/ -v /var/lib/docker/volumes/s4e_build/_data/:/home/s4e-builder/build -v /var/lib/docker/volumes/s4e_install/_data/:/home/s4e-builder/install/ s4e-llvm-builder s4e-builder 2001 b_scale4edge check

