FROM debian:bookworm as build

ARG boost_version=1.84.0
ARG boost_dir=boost_1_84_0

RUN set -eux; \
    apt update -y; \
    apt install -y wget gpg; \
    wget -O - https://apt.corretto.aws/corretto.key | gpg --dearmor -o /usr/share/keyrings/corretto-keyring.gpg; \
    echo "deb [signed-by=/usr/share/keyrings/corretto-keyring.gpg] https://apt.corretto.aws stable main" | tee /etc/apt/sources.list.d/corretto.list; \
    apt update -y; \
    apt install -y git make libtool automake libpcre2-dev bison patchelf java-11-amazon-corretto-jdk libicu-dev gcc g++; \
    cd $HOME; \
    git clone https://github.com/swig/swig.git; \
    wget https://boostorg.jfrog.io/artifactory/main/release/${boost_version}/source/${boost_dir}.tar.gz; \
    tar xfz ${boost_dir}.tar.gz; \
    rm ${boost_dir}.tar.gz; \
    cd ${boost_dir}; \
    ./bootstrap.sh; \
    ./b2 --without-python --prefix=/usr -j 4 link=shared runtime-link=shared install; \
    cd .. && rm -rf ${boost_dir} && /sbin/ldconfig; \
    cd swig; \
    git checkout v4.1.1; \
    ./autogen.sh; \
    ./configure --prefix=/usr --without-android --without-csharp --without-d --without-go --without-guile --without-javascript --without-lua --without-mzscheme --without-ocaml --without-octave --without-perl5 --without-php --without-r --without-ruby --without-scilab --without-tcl --with-boost=/usr; \
    make; \
    make install; \
    cd .. && rm -rf swig
