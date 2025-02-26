#!/usr/bin/env bash

set -eux

# Default values
: "${ci:=false}"
: "${quantlib_version:=1.37}"
: "${boost_version:=1.87.0}"
: "${swig_version:=4.3.0}"
boost_dir="$(echo "boost_${boost_version//./_}")"

export quantlib_version boost_version boost_dir swig_version

# Check if running on macOS
if [ "$(uname)" != "Darwin" ]; then
    echo "Error: This script requires macOS."
    exit 1
fi

# Check if running on ARM architecture
if [ "$(uname -m)" != "arm64" ] && [ "$(uname -m)" != "aarch64" ]; then
    echo "Error: This script requires a Mac with Apple Silicon (M1/M2/M3)."
    echo "Current architecture: $(uname -m)"
    exit 1
fi

echo "Running on Apple Silicon Mac. Proceeding with the script..."

if [ -z "${GPG_PASSPHRASE}" ]; then
  echo "GPG passphrase environment variable is required."
  exit 1
fi

echo "Passphrase length: ${#GPG_PASSPHRASE}"  # This will show length only

docker_command_exists() {
    command -v "$1" >/dev/null 2>&1
}

if docker_command_exists docker; then
    echo "Docker is installed."
    docker --version
else
    echo "Docker is not installed but it is required."
    exit 1
fi

# Check and install ARM64 Homebrew if not present
if [ ! -f /opt/homebrew/bin/brew ]; then
    echo "ARM64 Homebrew not found. Installing..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
else
    echo "ARM64 Homebrew is already installed."
fi

# Check and install AMD64 Homebrew if not present
if [ ! -f /usr/local/bin/brew ]; then
  echo "AMD64 Homebrew not found. Installing..."
  arch -x86_64 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
else
    echo "AMD64 Homebrew is already installed."
fi

repo=bfrancojr

rm -rf $HOME/tmp/libs

if [ "$ci" = true ]; then
  for p in amd64 arm64; do
    docker buildx build --memory=20g --memory-swap=20g --ulimit stack=536870912 --ulimit nofile=32768 --platform linux/${p} -t ${repo}/qlbase:${p} --build-arg="boost_version=$boost_version" --build-arg="boost_dir=$boost_dir" --build-arg="swig_version=$swig_version" -f pn.ci.base.Dockerfile .
    docker buildx build --memory=20g --memory-swap=20g --ulimit stack=536870912 --ulimit nofile=32768 --platform linux/${p} --build-arg="cpu_arch=${p}" -t ${repo}/quantlib:${p} --build-arg="quantlib_version=$quantlib_version" -f pn.ci.quantlib.Dockerfile .
    mkdir -p $HOME/tmp/libs/${p}
    docker run -ti --platform linux/${p} --mount type=bind,source=$HOME/tmp/libs/${p},target=/libs ${repo}/quantlib:${p} /bin/sh -c 'cp /quantlib.tgz /libs'
  done
else
  for p in amd64 arm64; do
    docker buildx build --platform linux/${p} -t ${repo}/qlbase:${p} --build-arg="boost_version=$boost_version" --build-arg="boost_dir=$boost_dir" --build-arg="swig_version=$swig_version" -f pn.base.Dockerfile .
    docker buildx build --platform linux/${p} --build-arg="cpu_arch=${p}" -t ${repo}/quantlib:${p} --build-arg="quantlib_version=$quantlib_version" -f pn.quantlib.Dockerfile .
    mkdir -p $HOME/tmp/libs/${p}
    docker run -ti --platform linux/${p} --mount type=bind,source=$HOME/tmp/libs/${p},target=/libs ${repo}/quantlib:${p} /bin/sh -c 'cp /quantlib.tgz /libs'
  done
fi

cat << 'EOF' > $HOME/tmp/localbuild.sh
#!/usr/bin/env bash
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
brew install --quiet boost automake pcre2 wget icu4c xz zstd llvm bison cmake m4 gnupg
brew link m4 --force
boostbrew="$(brew --cellar boost)/$(brew list --version boost | tail -1 | cut -d' ' -f2)"
export CXX="$(brew --cellar llvm)/$(brew list --version llvm | tail -1 | cut -d' ' -f2)/bin/clang++"
chmod -R +w "${boostbrew}"
cd $HOME/tmp
rm -f "$boost_dir.*"
rm -rf "$boost_dir"
wget "https://archives.boost.io/release/${boost_version}/source/${boost_dir}.tar.gz"
tar -xzf "$boost_dir.tar.gz"
rm "$boost_dir.tar.gz"
cd "$boost_dir"
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
destDir="$HOME/tmp/local/${cpu_arch}"
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

chmod +x $HOME/tmp/localbuild.sh
rm -rf $HOME/tmp/local

# building darwin/arm64 binaries
echo "Building darwin/arm64 binaries..."
/bin/bash -c "$HOME/tmp/localbuild.sh"

# building darwin/amd64 binaries
echo "Building darwin/amd64 binaries..."
arch -x86_64 /bin/bash -c "$HOME/tmp/localbuild.sh"

# combining all natives libraries as part of the jar
echo "Combining all natives libraries as part of the jar..."
for p in amd64 arm64; do
  cd $HOME/tmp/libs/${p}
  tar -xzf quantlib.tgz
  mkdir -p "$HOME/tmp/QuantLib-SWIG/Java/libraries/linux/${p}"
  cp java/lib* "$HOME/tmp/QuantLib-SWIG/Java/libraries/linux/${p}"
  cp lib/lib*.so "$HOME/tmp/QuantLib-SWIG/Java/libraries/linux/${p}"
  mkdir -p "$HOME/tmp/QuantLib-SWIG/Java/libraries/darwin/${p}"
  cp $HOME/tmp/local/${p}/java/* "$HOME/tmp/QuantLib-SWIG/Java/libraries/darwin/${p}"
done

cd $HOME/tmp/QuantLib-SWIG/Java
distDir="$HOME/tmp/dist"
packageDir="${distDir}/io/peernova/maven/quantlib/${quantlib_version}"
mkdir -p "${packageDir}"
jar cf "${packageDir}/quantlib-${quantlib_version}.jar" -C bin org libraries
javadoc -d docs org/quantlib/*
jar cf "${packageDir}/quantlib-${quantlib_version}-javadoc.jar" -C docs .
jar cf "${packageDir}/quantlib-${quantlib_version}-sources.jar" org
cd "${packageDir}"

cat << EOF >quantlib-${quantlib_version}.pom
<?xml version="1.0" encoding="UTF-8"?>
<project xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 https://maven.apache.org/xsd/maven-4.0.0.xsd" xmlns="http://maven.apache.org/POM/4.0.0"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
    <modelVersion>4.0.0</modelVersion>
    <groupId>io.peernova.maven</groupId>
    <artifactId>quantlib</artifactId>
    <version>${quantlib_version}</version>
    <packaging>jar</packaging>

    <name>QuantLib</name>
    <description>QuantLib binding for Java.</description>
    <url>https://github.com/peernova/quantLib-SWIG</url>

    <licenses>
        <license>
            <name>QuantLib</name>
            <url>https://github.com/peernova/quantLib-SWIG?tab=License-1-ov-file#readme</url>
        </license>
    </licenses>

    <developers>
        <developer>
            <name>Luigi Ballabio</name>
            <email>luigi.ballabio@gmail.com</email>
            <organization>QuantLib project</organization>
            <organizationUrl>https://www.implementingquantlib.com</organizationUrl>
        </developer>
    </developers>

    <scm>
        <connection>scm:git:git://github.com/peernova/quantLib-SWIG.git</connection>
        <developerConnection>scm:git:ssh://github.com:peernova/QuantLib-SWIG.git</developerConnection>
        <url>https://github.com/peernova/QuantLib-SWIG/tree/peernova</url>
    </scm>
</project>
EOF

for f in *.jar *.pom; do
  # Generate checksums
  cat "${f}" | md5 >"${f}.md5"
  cat "${f}" | shasum | cut -d ' ' -f 1 >"${f}.sha1"
  
  # Add a small delay between GPG operations to prevent lock contention
  sleep 5
  
  # Use a timeout and retry mechanism for GPG signing
  max_attempts=5
  attempt=1
  success=false
  
  while [ $attempt -le $max_attempts ] && [ "$success" = false ]; do
    echo "Signing ${f} (attempt ${attempt}/${max_attempts})..."
    if echo "${GPG_PASSPHRASE}" | gpg --armor --detach-sign --batch --yes --pinentry-mode=loopback --passphrase-fd 0 "${f}"; then
      success=true
      echo "Successfully signed ${f}"
    else
      echo "Failed to sign ${f}, waiting before retry..."
      # Kill any stuck gpg-agent processes (optional, use with caution)
      pkill -f gpg-agent
      sleep 5
      attempt=$((attempt+1))
    fi
  done
  
  if [ "$success" = false ]; then
    echo "Failed to sign ${f} after ${max_attempts} attempts"
    exit 1
  fi
done


cd "${distDir}"
zip -r "${HOME}/quantlib-${quantlib_version}".zip io

rm -rf $HOME/tmp/libs
rm -rf $HOME/tmp/local
rm -rf $HOME/tmp/localbuild.sh
rm -rf $HOME/tmp/QuantLib
rm -rf $HOME/tmp/QuantLib-SWIG
rm -rf $HOME/tmp/boost*

