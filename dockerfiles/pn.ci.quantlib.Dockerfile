ARG cpu_arch=amd64

FROM bfrancojr/qlbase:${cpu_arch} AS build

ENV CXXFLAGS="-O0 -fvisibility=default -march=x86-64 -mtune=generic"
ENV MAKEFLAGS="-j1"

ARG quantlib_version=1.36

RUN set -eux; \
    cd $HOME; \
    git clone --recurse https://github.com/lballabio/QuantLib.git; \
    cd QuantLib; \
    git checkout "v${quantlib_version}"; \
    mkdir -p $HOME/local; \
    mkdir build; \
    cd build; \
    ARCH=$(uname -m); \
    if [ "$ARCH" = "aarch64" ] || [ "$ARCH" = "arm64" ]; then \
    ARCH_FLAGS="-march=armv8-a"; \
    else \
    ARCH_FLAGS="-march=x86-64"; \
    fi; \
    cmake .. -G "Unix Makefiles" \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_CXX_FLAGS="-O0 ${ARCH_FLAGS} -mtune=generic" \
    -DQL_ENABLE_SESSIONS=ON \
    -DQL_ENABLE_THREAD_SAFE_OBSERVER_PATTERN=ON \
    -DQL_BUILD_BENCHMARK=OFF \
    -DQL_BUILD_EXAMPLES=OFF \
    -DQL_BUILD_TEST_SUITE=OFF \
    -DCMAKE_INSTALL_PREFIX=$HOME/local; \
    make -j1; \
    make install; \
    [[ "$(uname)" == "Linux" ]] && patchelf --set-soname libQuantLib.so $HOME/local/lib/libQuantLib.so; \
    /sbin/ldconfig $HOME/local/lib

RUN set -eux; \
    cd $HOME; \
    git clone --recurse https://github.com/peernova/QuantLib-SWIG.git; \
    cd $HOME/QuantLib-SWIG; \
    git checkout peernova; \
    git remote add upstream https://github.com/lballabio/quantlib-SWIG; \
    git pull upstream "v${quantlib_version}"; \
    ./autogen.sh; \
    export PATH=$PATH:$HOME/local/bin; \
    CXXFLAGS="-g -O0 -I/usr/include/boost -I$HOME/local/include" ./configure --with-jdk-include=/usr/lib/jvm/java-11-amazon-corretto/include --with-jdk-system-include=/usr/lib/jvm/java-11-amazon-corretto/include/linux --disable-java-finalizer --prefix=$HOME/local; \
    cd Java; \
    mkdir -p org/quantlib; \
    swig -DJAVA_AUTOLOAD -java -c++ -outdir org/quantlib -package org.quantlib -o quantlib_wrap.cpp ../SWIG/quantlib.i; \
    make -j1; \
    mkdir -p $HOME/local/java; \
    cp libQuantLibJNI.* QuantLib.jar $HOME/local/java

RUN set -eux; \
    cd $HOME/local; \
    tar czf ../quantlib.tgz .

FROM --platform=linux/${cpu_arch} debian:bookworm

COPY --from=build /root/quantlib.tgz /

CMD [ "bash" ]

