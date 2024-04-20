#!/bin/bash

set -eux

if [ "$(uname -m)" != "arm64" ] && [ "$(uname -m)" != "aarch64" ]; then
  echo "this script requires a mac M1/M2 arm machine"
  exit 1
fi

if ! which -s docker; then
  echo "docker is required"
  exit 1
fi

if [ ! -f /opt/homebrew/bin/brew ]; then
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

if [ ! -f /usr/local/bin/brew ]; then
  arch -x86_64 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

repo=bfrancojr

docker system prune -f

rm -rf /tmp/libs

for p in amd64 arm64; do
  docker build --platform linux/${p} -t ${repo}/qlbase:${p} -f pn.base.Dockerfile .
  docker build --platform linux/${p} --build-arg="cpu_arch=${p}" -t ${repo}/quantlib:${p} -f pn.quantlib.Dockerfile .
  mkdir -p /tmp/libs/${p}
  docker run -ti --mount type=bind,source=/tmp/libs/${p},target=/libs ${repo}/quantlib:${p} \
     /bin/sh -c 'cp /quantlib.tgz /libs'
done

cat << 'EOF' >/tmp/localbuild.sh
set -eux
cpu_arch="$(uane -m | sed 's/aarch/arm/' | sed 's/x86./amd/')"
if [ "${cpu_arch}" == "amd64" ]; then
  eval "$(/usr/local/bin/brew shellenv)"
else
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi
brew install boost automake pcre2
boostdir="$(brew --cellar boost)/$(brew list --version boost | tail -1 | cut -d' ' -f2)"
cd /tmp
if ! which -s swig || [ "$(swig -version | head -2 | tail -1 | cut -d' ' -f 3)" != "4.1.1" ]; then 
  if brew list swig; then
    brew uninstall swig
  fi
  rm -rf swig
  git clone https://github.com/swig/swig.git
  cd swig
  git checkout v4.1.1;
  ./autogen.sh
  ./configure --prefix=$(brew --prefix) --without-android --without-csharp --without-d --without-go --without-guile --without-javascript --without-lua --without-mzscheme --without-ocaml --without-octave --without-perl5 --without-php --without-r --without-ruby --without-scilab --without-tcl --with-boost=${boostdir}
  make
  make install
  cd ..
  rm -rf swig
fi
rm -rf Quantlib
git clone --recurse https://github.com/lballabio/QuantLib.git
cd QuantLib
git checkout v1.33
mkdir -p /tmp/local
./autogen.sh
./configure --with-boost-include="${boostdir}/include" --prefix=/tmp/local --enable-sessions --enable-thread-safe-observer-pattern
make
make install
cd ..
rm -rf Quantlib-SWIG
git clone --recurse https://github.com/peernova/QuantLib-SWIG.git
cd QuantLib-SWIG
git checkout peernova
./autogen.sh
export PATH=$PATH:/tmp/local/bin
CXXFLAS="-g -O2 -I$boostdir/include/boost -I/tmp/local/include" ./configure --with-jdk-include=$(/usr/libexec/java_home -v11)/include --with-jdk-system-include=$(/usr/libexec/java_home -v11)/include/darwin  --disable-java-finalizer --prefix=/tmp/local
make -C Java
mkdir -p Java/libraries/darwin/${cpu_arch}
cp Java/libQuantlibJNI.dylib Java/libraries/darwin/${cpu_arch}
cp /tmp/local/lib/libQuantlib.dylib Java/libraries/darwin/${cpu_arch}
EOF

rm -rf /tmp/local

# building darwin/arm64 binaries
/bin/bash /tmp/localbuild.sh

# building darwin/amd64 binaries
arch -x86_64 /bin/bash /tmp/localbuild.sh

# combining all natives libraries as part of the jar
for p amd64 arm64; do
  cd /tmp/libs/${p}
  tar -xzf quantlib.tgz
  cp java/* /tmp/QuantLib-SWIG/Java/libraries/darwin/${p}
done

cd /tmp/QuantLib-SWIG/Java
jar cf $HOME/QunatLib.jar -C bin org libraries

rm -rf /tmp/libs
rm -rf /tmp/localbuild.sh
rm -rf /tmp/QuantLib
rm -rf /tmp/QuantLib-SWIG
