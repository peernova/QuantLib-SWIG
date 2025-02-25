ARG cpu_arch=amd64

FROM bfrancojr/qlbase:${cpu_arch} AS build

ARG quantlib_version=1.37


RUN set -eux; \
    cd $HOME; \
    git clone --recurse https://github.com/lballabio/QuantLib.git; \
    git clone --recurse https://github.com/peernova/QuantLib-SWIG.git; \
    cd $HOME/QuantLib; \
    git checkout "v${quantlib_version}"; \
    cd $HOME/QuantLib-SWIG; \
    git checkout peernova; \
    git remote add upstream https://github.com/lballabio/quantlib-SWIG; \
    git checkout .; \
    git pull upstream "v${quantlib_version}"

RUN set -eux; \
    cd $HOME/QuantLib; \
    mkdir -p $HOME/local; \
    mkdir build; \
    cd build; \
    cmake .. -G "Unix Makefiles" \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_CXX_FLAGS="-O0 -fPIC -g" \
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
    cd $HOME/QuantLib-SWIG; \
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