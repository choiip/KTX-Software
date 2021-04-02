FROM debian:stable-slim AS buildenv

# renovate: datasource=github-releases depName=Kitware/CMake
ARG CMAKE_VERSION=3.19.7

RUN apt-get -qq update \
 && apt-get -qq install gcc g++ ninja-build \
 && apt-get -qq install libzstd-dev libsdl2-dev \
 && apt-get -qq install libgl1-mesa-glx libgl1-mesa-dev \
 && apt-get -qq install libvulkan1 libvulkan-dev \
 && apt-get -qq install rpm wget \
 && apt-get -qq install python3.7 python3-pip \
 && pip3 install reuse \
 && wget https://github.com/Kitware/CMake/releases/download/v${CMAKE_VERSION}/cmake-${CMAKE_VERSION}-Linux-$(uname -m).sh \
      -q -O /tmp/cmake-install.sh \
      && chmod u+x /tmp/cmake-install.sh \
      && /tmp/cmake-install.sh --skip-license --prefix=/usr \
      && rm /tmp/cmake-install.sh

FROM buildenv AS builder
COPY . /src
WORKDIR /src

RUN echo "Configure KTX-Software (Linux Release)" \
 && cd /src \
 && cmake -G Ninja -Bbuild-linux-release -DCMAKE_BUILD_TYPE=Release -KTX_FEATURE_TESTS=OFF -DBASISU_SUPPORT_SSE=$(expr `uname -m` == 'x86_64') . \
 && cd build-linux-release \
 && echo "Build KTX-Software (Linux Release)" \
 && cmake --build . \
 && echo "Pack KTX-Software (Linux Release)" \
 && cpack -G TGZ

FROM debian:stable-slim
COPY --from=builder /src/build-linux-release/*.tar.gz /tmp
RUN cd /tmp \
 && BASENAME=`basename $(ls *.tar.gz | head -1) .tar.gz` \
 && tar zxf ${BASENAME}.tar.gz \
 && cp -R ${BASENAME}/bin ${BASENAME}/lib /usr \
 && rm -rf ${BASENAME}*
RUN groupadd -r runner && useradd -r -g runner runner
USER runner

WORKDIR /work