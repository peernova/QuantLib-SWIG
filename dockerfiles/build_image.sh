#!/usr/bin/env bash

set -eux

quantlib_version=1.34
boost_version=1.85.0
swig_version=4.2.0
boost_dir="$(echo "boost_${boost_version//./_}")"

export quantlib_version boost_version boost_dir swig_version

if [ "$(uname -m)" != "arm64" ] && [ "$(uname -m)" != "aarch64" ]; then
  echo "this script requires a mac M1/M2 arm machine"
  exit 1
fi

if [ ! -v GPG_PASSPHRASE ] || [ -z "${GPG_PASSPHRASE}" ]; then
  echo "gpg passphrase environment variable is required"
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

rm -rf /tmp/libs

for p in amd64 arm64; do
  docker build --platform linux/${p} -t ${repo}/qlbase:${p} --build-arg="boost_version=${boost_version}" --build-arg="boost_dir=${boost_dir}" --build-arg="swig_version=${swig_version}" -f pn.base.Dockerfile .
  docker build --platform linux/${p} --build-arg="cpu_arch=${p}" -t ${repo}/quantlib:${p} --build-arg="quantlib_version=${quantlib_version}" -f pn.quantlib.Dockerfile .
  mkdir -p /tmp/libs/${p}
  docker run -ti --platform linux/${p} --mount type=bind,source=/tmp/libs/${p},target=/libs ${repo}/quantlib:${p} \
     /bin/sh -c 'cp /quantlib.tgz /libs'
done

cat << 'EOF' >/tmp/localbuild.sh
set -eux
cpu_arch="$(uname -m | sed 's/aarch/arm/' | sed 's/x86./amd/')"
if [ "${cpu_arch}" == "amd64" ]; then
  eval "$(/usr/local/bin/brew shellenv | grep -v 'export PATH=')"
  export PATH=/usr/local/bin:/usr/local/opt/bison/bin:/usr/local/sbin:/usr/bin:/bin:/usr/sbin:/sbin
  boostinc="-I/usr/local/include"
  boostld="-Z -L/usr/lib -L/usr/local/lib"
else
  eval "$(/opt/homebrew/bin/brew shellenv | grep -v 'export PATH=')"
  export PATH=/opt/homebrew/bin:/opt/homebrew/sbin:/opt/homebrew/opt/bison/bin:/usr/bin:/bin:/usr/sbin:/sbin
  boostinc="-I/opt/homebrew/include"
  boostld="-Z -L/usr/lib -L/opt/homebrew/lib"
fi
unset CXXFLAGS
unset CPPFLAGS
unset LDFLAGS
unset PKG_CONFIG_PATH
brew install boost automake pcre2 wget icu4c xz zstd llvm bison cmake
brew link m4 --force
boostbrew="$(brew --cellar boost)/$(brew list --version boost | tail -1 | cut -d' ' -f2)"
export CXX="$(brew --cellar llvm)/$(brew list --version llvm | tail -1 | cut -d' ' -f2)/bin/clang++"
chmod -R +w "${boostbrew}"
cd /tmp
rm -f "${boost_dir}.*"
rm -rf "${boost_dir}"
wget "https://boostorg.jfrog.io/artifactory/main/release/${boost_version}/source/${boost_dir}.tar.gz"
tar -xzf "${boost_dir}.tar.gz"
rm "${boost_dir}.tar.gz"
cd "${boost_dir}"
./bootstrap.sh --prefix="${boostbrew}"
./b2 boost.stacktrace.from_exception=off --without-python --prefix="${boostbrew}" -j 4 link=shared runtime-link=shared cxxflags="${boostinc}" linkflags="${boostld}" install
cd ..
if ! which -s swig || [ "$(swig -version | head -2 | tail -1 | cut -d' ' -f 3)" != "${swig_version}" ]; then
  if brew list swig; then
    brew uninstall swig
  fi
  rm -rf swig
  git clone https://github.com/swig/swig.git
  cd swig
  git checkout "v${swig_version}"
  ./autogen.sh
  ./configure --prefix=$(brew --prefix) --without-android --without-csharp --without-d --without-go --without-guile --without-javascript --without-lua --without-mzscheme --without-ocaml --without-octave --without-perl5 --without-php --without-python --without-python3 --without-r --without-ruby --without-scilab --without-tcl --with-boost=${boostbrew}
  make
  make install
  cd ..
  rm -rf swig
fi
rm -rf Quantlib
git clone --recurse https://github.com/lballabio/QuantLib.git
cd QuantLib
git checkout "v${quantlib_version}"
destDir="/tmp/local/${cpu_arch}"
mkdir -p "${destDir}"
mkdir -p build
cd build
cmake .. -G "Unix Makefiles" -DCMAKE_BUILD_TYPE=Release -DQL_ENABLE_SESSIONS=ON -DQL_ENABLE_THREAD_SAFE_OBSERVER_PATTERN=ON -DQL_BUILD_BENCHMARK=OFF -DQL_BUILD_EXAMPLES=OFF -DQL_BUILD_TEST_SUITE=OFF -DCMAKE_INSTALL_PREFIX="${destDir}"
make
make install
cd ../..
rm -rf Quantlib-SWIG
git clone --recurse https://github.com/peernova/QuantLib-SWIG.git
cd QuantLib-SWIG
git checkout peernova
git remote add upstream https://github.com/lballabio/quantlib-SWIG
git pull upstream "v${quantlib_version}" --ff
./autogen.sh
export PATH=$PATH:"${destDir}/bin"
CXXFLAGS="-g -O2 -I${boostbrew}/include -I${destDir}/include" ./configure --with-jdk-include=$(/usr/libexec/java_home -v11)/include --with-jdk-system-include=$(/usr/libexec/java_home -v11)/include/darwin  --disable-java-finalizer --prefix="${destDir}"
make -C Java
mkdir -p "${destDir}/java"
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
  cp java/lib* "/tmp/QuantLib-SWIG/Java/libraries/linux/${p}"
  cp lib/lib*.so "/tmp/QuantLib-SWIG/Java/libraries/linux/${p}"
  mkdir -p "/tmp/QuantLib-SWIG/Java/libraries/darwin/${p}"
  cp /tmp/local/${p}/java/* "/tmp/QuantLib-SWIG/Java/libraries/darwin/${p}"
done

cd /tmp/QuantLib-SWIG/Java
distDir="/tmp/dist"
packageDir="${distDir}/io/peernova/maven/quantlib/${quantlib_version}"
mkdir -p "${packageDir}"
jar cf "${packageDir}/quantlib-${quantlib_version}.jar" -C bin org libraries
javadoc -d docs org/quantlib/*
jar cf "${packageDir}/quantlib-${quantlib_version}-javadoc.jar" -C docs .
jar cf "${packageDir}/quantlib-${quantlib_version}-sources.jar" org
cd "${packageDir}"
for f in *.jar; do
  cat "${f}" | md5 >"${f}.md5"
  cat "${f}" | shasum | cut -d ' ' -f 1 >"${f}.sha1"
  echo "${GPG_PASSPHRASE}" | gpg --armor --detach-sign --batch --yes --pinentry-mode=loopback --passphrase-fd 0 "${f}"
done
cd "${distDir}"
zip -r "${HOME}/quantlib-${quantlib_version}".zip io

rm -rf /tmp/libs
rm -rf /tmp/local
rm -rf /tmp/localbuild.sh
rm -rf /tmp/QuantLib
rm -rf /tmp/QuantLib-SWIG
rm -rf /tmp/boost*
