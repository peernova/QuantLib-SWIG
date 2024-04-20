FROM --platform=$BUILDPLATFORM public.ecr.aws/lambda/java:11 as build

ARG boost_version=1.84.0
ARG boost_dir=boost_1_84_0

RUN set -eux; \
    rpm --import https://yum.corretto.aws/corretto.key; \
    curl -L -o /etc/yum.repos.d/corretto.repo https://yum.corretto.aws/corretto.repo; \
    yum update -y; \
    yum install -y git make libtool automake clang pcre2-devel bison patch patchelf java-11-amazon-corretto-devel libicu-devel which wget; \
    git clone https://github.com/swig/swig.git; \
    git clone --recurse https://github.com/lballabio/QuantLib.git; \
    git clone --recurse https://github.com/peernova/QuantLib-SWIG.git; \
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
    cd ../QuantLib; \
    git checkout v1.33; \
    mkdir $HOME/local; \
    ./autogen.sh; \
    ./configure --with-boost-include="/usr/include/boost" --prefix=$HOME/local --enable-sessions --enable-thread-safe-observer-pattern; \
    make install; \
    [[ "$(uname)" == "Linux" ]] && patchelf --set-soname libQuantLib.so $HOME/local/lib/libQuantLib.so; \
    pushd . >/dev/null; \
    cd $HOME/lib; \
    /sbin/ldconfig $HOME/local/lib; \
    popd; \
    cd ../QuantLib-SWIG; \
    git checkout peernova; \
    ./autogen.sh; \
    export PATH=$PATH:$HOME/local/bin; \
    CXXFLAS="-g -O2 -I/usr/include/boost -I/local/include" ./configure --with-jdk-include=/usr/lib/jvm/java/include --with-jdk-system-include=/usr/lib/jvm/java/include/linux --disable-java-finalizer --prefix=$HOME/local; \
    make -C Java; \
    mkdir -p $HOME/local/java; \
    cp Java/libQuantLibJNI.* Java/QuantLib.jar $HOME/local/java; \
    cd $HOME/local; \
    tar czf ../quantlib-linux-`uname -m`.tgz .

CMD [ "bash" ]

