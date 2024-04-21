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
  docker run -ti --platform linux/${p} --mount type=bind,source=/tmp/libs/${p},target=/libs ${repo}/quantlib:${p} \
     /bin/sh -c 'cp /quantlib.tgz /libs'
done

cat << 'EOF' >/tmp/localbuild.sh
set -eux
boost_version=1.84.0
boost_dir=boost_1_84_0
cpu_arch="$(uname -m | sed 's/aarch/arm/' | sed 's/x86./amd/')"
if [ "${cpu_arch}" == "amd64" ]; then
  eval "$(/usr/local/bin/brew shellenv | grep -v 'export PATH=')"
  export PATH=/usr/local/bin:/usr/local/sbin:/usr/bin:/bin:/usr/sbin:/sbin
  boostinc="-I/usr/local/include"
  boostld="-Z -L/usr/lib -L/usr/local/lib"
else
  eval "$(/opt/homebrew/bin/brew shellenv | grep -v 'export PATH=')"
  export PATH=/opt/homebrew/bin:/opt/homebrew/sbin:/usr/bin:/bin:/usr/sbin:/sbin
  boostinc="-I/opt/homebrew/include"
  boostld="-Z -L/usr/lib -L/opt/homebrew/lib"
fi
unset CXXFLAGS
unset CPPFLAGS
unset LDFLAGS
unset PKG_CONFIG_PATH
brew install boost automake pcre2 wget icu4c xz zstd
brew link m4 --force
boostbrew="$(brew --cellar boost)/$(brew list --version boost | tail -1 | cut -d' ' -f2)"
chmod -R +w "${boostbrew}"
cd /tmp
rm -f "${boost_dir}.*"
rm -rf "${boost_dir}"
wget "https://boostorg.jfrog.io/artifactory/main/release/${boost_version}/source/${boost_dir}.tar.gz"
tar -xzf "${boost_dir}.tar.gz"
rm "${boost_dir}.tar.gz"
cd "${boost_dir}"
./bootstrap.sh --prefix="${boostbrew}"
./b2 --without-python --prefix="${boostbrew}" -j 4 link=shared runtime-link=shared cxxflags="${boostinc}" linkflags="${boostld}" install
cd ..
if ! which -s swig || [ "$(swig -version | head -2 | tail -1 | cut -d' ' -f 3)" != "4.1.1" ]; then 
  if brew list swig; then
    brew uninstall swig
  fi
  rm -rf swig
  git clone https://github.com/swig/swig.git
  cd swig
  git checkout v4.1.1;
  ./autogen.sh
  ./configure --prefix=$(brew --prefix) --without-android --without-csharp --without-d --without-go --without-guile --without-javascript --without-lua --without-mzscheme --without-ocaml --without-octave --without-perl5 --without-php --without-r --without-ruby --without-scilab --without-tcl --with-boost=${boostbrew}
  make
  make install
  cd ..
  rm -rf swig
fi
rm -rf Quantlib
git clone --recurse https://github.com/lballabio/QuantLib.git
cd QuantLib
git checkout v1.33
destDir="/tmp/local/${cpu_arch}"
mkdir -p "${destDir}"
./autogen.sh
./configure --with-boost-include="${boostbrew}/include" --prefix="${destDir}" --enable-sessions --enable-thread-safe-observer-pattern
make
make install
cd ..
rm -rf Quantlib-SWIG
git clone --recurse https://github.com/peernova/QuantLib-SWIG.git
cd QuantLib-SWIG
git checkout peernova
./autogen.sh
export PATH=$PATH:"${destDir}/bin"
CXXFLAS="-g -O2 -I${boostbrew}/include/boost -I${destDir}/include" ./configure --with-jdk-include=$(/usr/libexec/java_home -v11)/include --with-jdk-system-include=$(/usr/libexec/java_home -v11)/include/darwin  --disable-java-finalizer --prefix="${destDir}"
make -C Java
mkdir -p "${dstDir}/java"
cp Java/libQuantLibJNI.jnilib "${destDir}/java"
cp ${destDir}/lib/libQuantLib.dylib "${destDir}/java"
EOF

rm -rf /tmp/local

# building darwin/arm64 binaries
/bin/bash /tmp/localbuild.sh

# building darwin/amd64 binaries
arch -x86_64 /bin/bash /tmp/localbuild.sh

# combining all natives libraries as part of the jar
for p in amd64 arm64; do
  cd /tmp/libs/${p}
  tar -xzf quantlib.tgz
  mkdir -p "/tmp/QuantLib-SWIG/Java/libraries/linux/${p}"
  cp java/* "/tmp/QuantLib-SWIG/Java/libraries/linux/${p}"
  cp /tmp/local/${p}/java/* "/tmp/QuantLib-SWIG/Java/libraries/darwin/${p}"
done

cd /tmp/QuantLib-SWIG/Java
jar cf $HOME/QunatLib.jar -C bin org libraries

exit

rm -rf /tmp/libs
rm -rf /tmp/local
rm -rf /tmp/localbuild.sh
rm -rf /tmp/QuantLib
rm -rf /tmp/QuantLib-SWIG
rm -rf /tmp/boost*
