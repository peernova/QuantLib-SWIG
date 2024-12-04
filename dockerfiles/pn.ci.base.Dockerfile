FROM debian:bookworm AS build

ENV MAKEFLAGS="-j1"
ENV CXXFLAGS="-O0 -fvisibility=default -fno-inline -fno-omit-frame-pointer"
ENV CFLAGS="-O0"
ENV LINCFLAGS="-O0"
ENV LDFLAGS="-Wl,--no-as-needed -ldl"

ARG boost_version=1.86.0
ARG boost_dir=boost_1_86_0
ARG swig_version=4.2.0

RUN set -eux; \
    apt update; \
    apt install -y wget gpg make cmake; \
    apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys A122542AB04F24E3; \
    wget -O - https://apt.corretto.aws/corretto.key | gpg --dearmor -o /usr/share/keyrings/corretto-keyring.gpg; \
    echo "deb [signed-by=/usr/share/keyrings/corretto-keyring.gpg] https://apt.corretto.aws stable main" | tee /etc/apt/sources.list.d/corretto.list; \
    apt update; \
    apt install -y git make libtool automake libpcre2-dev bison patchelf java-11-amazon-corretto-jdk libicu-dev gcc g++ graphviz build-essential libboost-all-dev libstdc++-12-dev; \
    cd $HOME; \
    git clone https://github.com/swig/swig.git; \
    wget https://boostorg.jfrog.io/artifactory/main/release/${boost_version}/source/${boost_dir}.tar.gz; \
    tar xfz ${boost_dir}.tar.gz; \
    rm ${boost_dir}.tar.gz; \
    cd ${boost_dir}; \
    ./bootstrap.sh; \
    ./b2 \
    boost.stacktrace.from_exception=off \
    --without-python \
    --prefix=/usr \
    -j1 \
    link=shared \
    runtime-link=shared \
    install; \
    cd .. && rm -rf ${boost_dir} && /sbin/ldconfig; \
    cd swig; \
    git checkout "v${swig_version}"; \
    ./autogen.sh; \
    ./configure --prefix=/usr --without-android --without-csharp --without-d --without-go --without-guile --without-javascript --without-lua --without-mzscheme --without-ocaml --without-octave --without-perl5 --without-php --without-python --without-python3 --without-r --without-ruby --without-scilab --without-tcl --with-boost=/usr; \
    make -j1; \
    make install; \
    cd .. && rm -rf swig
