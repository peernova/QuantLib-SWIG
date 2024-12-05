FROM debian:bookworm AS build

ENV MAKEFLAGS="-j1"
ENV CXXFLAGS="-O1 -g -fno-strict-aliasing"
ENV CFLAGS="-O1 -g"
ENV LDFLAGS="-Wl,--no-as-needed -ldl"

ARG boost_version=1.86.0
ARG boost_dir=boost_1_86_0
ARG swig_version=4.2.0

RUN set -eux; \
    apt update; \
    apt install -y wget gpg cmake make; \
    apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys A122542AB04F24E3; \
    wget -O - https://apt.corretto.aws/corretto.key | gpg --dearmor -o /usr/share/keyrings/corretto-keyring.gpg; \
    echo "deb [signed-by=/usr/share/keyrings/corretto-keyring.gpg] https://apt.corretto.aws stable main" | tee /etc/apt/sources.list.d/corretto.list; \
    apt update; \
    apt install -y git libtool automake libpcre2-dev bison patchelf java-11-amazon-corretto-jdk libicu-dev gcc g++ graphviz build-essential libboost-all-dev libstdc++-12-dev

RUN set -eux; \
    wget https://boostorg.jfrog.io/artifactory/main/release/${boost_version}/source/${boost_dir}.tar.gz; \
    tar xfz ${boost_dir}.tar.gz; \
    rm ${boost_dir}.tar.gz; \
    cd ${boost_dir}; \
    ./bootstrap.sh --with-toolset=gcc; \
    ulimit -n 4096; \
    ulimit -s 16384; \
    ./b2 \
        -j1 \
        boost.stacktrace.from_exception=off \
        --without-python \
        --prefix=/usr \
        variant=release \
        debug-symbols=off \
        link=shared \
        runtime-link=shared \
        threading=multi \
        --layout=system \
        install; \
    cd .. && rm -rf ${boost_dir} && /sbin/ldconfig

RUN set -eux; \
    cd $HOME; \
    git clone https://github.com/swig/swig.git; \
    cd swig; \
    git checkout "v${swig_version}"; \
    ulimit -n 4096; \
    ./autogen.sh; \
    ./configure --prefix=/usr \
        --without-android --without-csharp --without-d \
        --without-go --without-guile --without-javascript \
        --without-lua --without-mzscheme --without-ocaml \
        --without-octave --without-perl5 --without-php \
        --without-python --without-python3 --without-r \
        --without-ruby --without-scilab --without-tcl \
        --with-boost=/usr; \
    make -j1; \
    make install; \
    cd .. && rm -rf swig
