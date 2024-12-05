FROM debian:bookworm AS build

ARG boost_version=1.86.0
ARG boost_dir=boost_1_86_0
ARG swig_version=4.2.0

RUN set -eux; \
    apt update && apt install -y wget gpg cmake make build-essential libbz2-dev libzstd-dev liblzma-dev; \
    apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys A122542AB04F24E3; \
    wget -O - https://apt.corretto.aws/corretto.key | gpg --dearmor -o /usr/share/keyrings/corretto-keyring.gpg; \
    echo "deb [signed-by=/usr/share/keyrings/corretto-keyring.gpg] https://apt.corretto.aws stable main" | tee /etc/apt/sources.list.d/corretto.list; \
    apt update && apt install -y \
    git libtool automake \
    libpcre2-dev bison patchelf \
    java-11-amazon-corretto-jdk \
    libicu-dev gcc g++ graphviz \
    zlib1g-dev libc6-dev libboost-all-dev libstdc++-12-dev; \
    rm -rf /var/lib/apt/lists/*

RUN set -eux; \
    wget https://boostorg.jfrog.io/artifactory/main/release/${boost_version}/source/${boost_dir}.tar.gz; \
    tar xfz ${boost_dir}.tar.gz; \
    rm ${boost_dir}.tar.gz; \
    cd ${boost_dir}; \
    sed -i 's/-O2/-O0/g' bootstrap.sh; \
    sed -i 's/-O3/-O0/g' bootstrap.sh; \
    ulimit -s unlimited; \
    ulimit -n 4096; \
    ./bootstrap.sh; \
    echo "using gcc ;" > user-config.jam; \
    ./b2 install \
        boost.stacktrace.from_exception=off \
        --prefix=/usr \
        -j1 \
        link=shared \
        runtime-link=shared \
        cxxflags="-O0 -g" \
        linkflags="-Wl,--no-as-needed" \
        --build-dir=build \
        --layout=system \
        threading=multi \
        variant=release \
        --with-locale \
        --with-test \
        --with-url \
        --with-system \
        --with-thread \
        --with-atomic; \
    cd .. && rm -rf ${boost_dir} && /sbin/ldconfig


RUN set -eux; \
    cd $HOME; \
    git clone https://github.com/swig/swig.git; \
    cd swig; \
    git checkout "v${swig_version}"; \
    ulimit -n 4096; \
    ./autogen.sh; \
    ./configure \
        --prefix=/usr --without-android --without-csharp \
        --without-d --without-go --without-guile --without-javascript \
        --without-lua --without-mzscheme --without-ocaml \
        --without-octave --without-perl5 --without-php \
        --without-python --without-python3 --without-r \
        --without-ruby --without-scilab --without-tcl \
        --with-boost=/usr; \
    make -j1; \
    make install; \
    cd .. && rm -rf swig
