FROM ozzyjohnson/cuda

MAINTAINER Ozzy Johnson <docker@ozzy.io>

ENV DEBIAN_FRONTEND noninteractive

ENV CUDA_RELEASE 6_5
ENV CUDA_VERSION 6.5.14
ENV CUDA_DRIVER 340.29
ENV CUDA_SERIAL 18749181
ENV CUDA_INSTALL http://developer.download.nvidia.com/compute/cuda/${CUDA_RELEASE}/rel/installers/cuda_${CUDA_VERSION}_linux_64.run

# Update and install minimal.
RUN apt-get update \
      --quiet \
    && apt-get install \
        -f \
        --yes \
        --no-install-recommends \
        --no-install-suggests \
    ca-certificates \
    cmake \
    cmake-curses-gui \
    git \
    libatlas3gf-base \
    libatlas-dev \
    libboost-all-dev \
    libfftw3-dev \
    libfreeimage-dev \
    subversion \
    
# Clean up packages.
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# OpenCL via CUDA toolkit.
RUN wget \
    $CUDA_INSTALL \
        -P /tmp \
        --no-verbose \
    && chmod +x /tmp/cuda_${CUDA_VERSION}_linux_64.run \
    && /tmp/cuda_${CUDA_VERSION}_linux_64.run \
        -extract=/tmp \ 
    && sh cuda-linux64-rel-${CUDA_VERSION}-${CUDA_SERIAL}.run -noprompt \
    && rm -rf /tmp/cuda* \
        /tmp/NVIDIA*

# Get ready to build.
WORKDIR /tmp

# clBlAS
RUN git clone https://github.com/arrayfire/clBLAS.git

# clFFT
RUN git clone https://github.com/arrayfire/clFFT.git

# boost.Compute
RUN git clone https://github.com/kylelutz/compute.git

# Arrayfire
RUN git clone https://github.com/arrayfire/arrayfire.git

# Compilation.
RUN cd clBLAS \
    && mkdir build \
    && cd build \
    && cmake ../src \
        -DCMAKE_BUILD_TYPE=Release \
        -DOPENCL_INCLUDE_DIRS=/usr/local/cuda-6.5/include \
    && make \
    && make install

RUN cd clFFT \
    && mkdir build \
    && cd build \
    && cmake ../src \
        -DCMAKE_BUILD_TYPE=Release \
        -DOPENCL_INCLUDE_DIRS=/usr/local/cuda-6.5/include \
    && make \
    && make install

RUN cd arrayfire \
    && mkdir build \
    && cd build \
    && cmake .. \
        -DCMAKE_BUILD_TYPE=Release \
        -DBUILD_CUDA=ON \
        -DBUILD_OPENCL=ON
    && make -j`getconf _NPROCESSORS_ONLN` \
    && make install 

# Data volume.
ONBUILD VOLUME /data

# Getting ready.
WORKDIR /data

# Default command.
ENTRYPOINT ["bash"]
