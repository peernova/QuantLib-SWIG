
ARG cpu_arch=amd64
ARG quantlib_version=1.34

FROM bfrancojr/qlbase:${cpu_arch} as build

RUN set -eux; \
    cd $HOME; \
    git clone --recurse https://github.com/lballabio/QuantLib.git; \
    git clone --recurse https://github.com/peernova/QuantLib-SWIG.git; \
    cd QuantLib; \
    git checkout "v${quantlib_version}"; \
    mkdir -p $HOME/local; \
    ./autogen.sh; \
    ./configure --with-boost-include="/usr/include/boost" --prefix=$HOME/local --enable-sessions --enable-thread-safe-observer-pattern; \
    make; \
    make install; \
    [[ "$(uname)" == "Linux" ]] && patchelf --set-soname libQuantLib.so $HOME/local/lib/libQuantLib.so; \
    /sbin/ldconfig $HOME/local/lib

RUN set -eux; \
    cd $HOME/QuantLib-SWIG; \
    git checkout peernova; \
    git pull upstream "v${quantlib_version}"; \
    ./autogen.sh; \
    export PATH=$PATH:$HOME/local/bin; \
    CXXFLAS="-g -O2 -I/usr/include/boost -I$HOME/local/include" ./configure --with-jdk-include=/usr/lib/jvm/java-11-amazon-corretto/include --with-jdk-system-include=/usr/lib/jvm/java-11-amazon-corretto/include/linux --disable-java-finalizer --prefix=$HOME/local; \
    make -C Java; \
    mkdir -p $HOME/local/java; \
    cp Java/libQuantLibJNI.* Java/QuantLib.jar $HOME/local/java

RUN set -eux; \
    cd $HOME/local; \
    tar czf ../quantlib.tgz .

FROM --platform=$BUILDPLATFORM debian:bookworm

COPY --from=build /root/quantlib.tgz /

CMD [ "bash" ]

