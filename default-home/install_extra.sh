#!/bin/bash
set -ex  # -x for verbose output, -e to exit on errors

MAKE_JOBS=$(nproc)
if [ "$MAKE_JOBS" -gt 4 ]; then MAKE_JOBS=4; fi

#export CFLAGS="-O2 -march=armv8-a"
#export CXXFLAGS="-O2 -march=armv8-a"
export CFLAGS="-O1 -march=armv8-a"
export CXXFLAGS="-O1 -march=armv8-a"

MAKE_JOBS=2

WORKDIR="/tmp/build"
mkdir -p "$WORKDIR"
cd "$WORKDIR"

# Clone libjxl only if missing
if [[ ! -d "libjxl" ]]; then
    echo "Cloning libjxl repository..."
    git clone --branch v0.11.x --depth 1 --recursive https://github.com/libjxl/libjxl.git
else
    echo "libjxl directory exists, skipping clone"
fi

cd libjxl

# Setup build directory
mkdir -p build
cd build

# Run cmake pointing correctly to source (one dir up, libjxl root folder)
cmake -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_INSTALL_PREFIX=/usr/local \
      -DBUILD_TESTING=OFF \
      -DJPEGXL_ENABLE_BENCHMARK=OFF \
      -DJPEGXL_ENABLE_EXAMPLES=OFF \
      -DJPEGXL_ENABLE_MANPAGES=OFF \
      -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
      -DCMAKE_POLICY_DEFAULT_CMP0111=NEW \
      -DCMAKE_POLICY_DEFAULT_CMP0091=NEW \
      -DCMAKE_POLICY_DEFAULT_CMP0110=NEW \
      -DCMAKE_POLICY_DEFAULT_CMP0119=NEW \
      -DCMAKE_POLICY_DEFAULT_CMP0121=NEW \
      -DCMAKE_POLICY_DEFAULT_CMP0124=NEW \
      -DCMAKE_POLICY_DEFAULT_CMP0126=NEW \
      -DCMAKE_POLICY_DEFAULT_CMP0127=NEW \
      -DCMAKE_POLICY_DEFAULT_CMP0135=NEW \
      -DCMAKE_POLICY_DEFAULT_CMP0136=NEW \
      -DCMAKE_POLICY_DEFAULT_CMP0137=NEW \
      -DCMAKE_POLICY_VERSION_MINIMUM=3.15 \
      ..

cmake --build . -- -j"$MAKE_JOBS"
cmake --install .

cd "$WORKDIR"



# Similarly for HarfBuzz, check folder, clone if missing, proper paths

if [[ ! -d "harfbuzz" ]]; then
    echo "Cloning HarfBuzz repository..."
    git clone --branch 11.5.0 --depth 1 https://github.com/harfbuzz/harfbuzz.git
else
    echo "harfbuzz directory exists, skipping clone"
fi

echo "Entering HarfBuzz directory..."
cd harfbuzz

# Create build directory if it doesn't exist
if [[ ! -d "build" ]]; then
    mkdir build
fi
cd build

echo "Configuring HarfBuzz build with Meson..."
# Point to parent directory (..) which contains meson.build
meson setup . .. \
  --buildtype=release \
  --prefix=/usr/local \
  -Dtests=disabled \
  -Ddocs=disabled \
  -Dbenchmark=disabled \
  -Dintrospection=disabled \
  -Dicu=disabled


ninja -j"$MAKE_JOBS"
ninja install

LIBUBREAK_DIR=/tmp/libunibreak
MAKE_JOBS=2

# Clone repo if not already present
if [[ ! -d "$LIBUBREAK_DIR" ]]; then
  echo "Cloning libunibreak repository..."
  git clone https://github.com/adah1972/libunibreak.git "$LIBUBREAK_DIR"
else
  echo "libunibreak source already present, skipping clone"
fi

cd "$LIBUBREAK_DIR/src"

echo "Copying Makefile.gcc to Makefile"
cp -p Makefile.gcc Makefile

echo "Running make"
make

echo "Running make release"
make release

echo "Build complete. Installing..."

cd ReleaseDir

echo "Copying static library libunibreak.a to /usr/local/lib/"
cp libunibreak.a /usr/local/lib/libunibreak.a

cd ..

echo "Copying headers to /usr/local/include/"
cp ../src/*.h /usr/local/include/

echo "Preparing pkg-config file"
echo $PWD
cd ..
PKGCONFIG_DEST=/usr/local/lib/pkgconfig
mkdir -p "$PKGCONFIG_DEST"

echo "Processing libunibreak.pc.in to libunibreak.pc"
sed -e 's|@prefix@|/usr/local|' -e 's|@VERSION@|6.1.0|' libunibreak.pc.in > "$PKGCONFIG_DEST/libunibreak.pc"

echo "Updating linker cache"
ldconfig

echo "libunibreak built and installed successfully."

cd /tmp
rm -rf /tmp/libunibreak

    
cd "$WORKDIR"

# Fix the cleanup (you had 'harbuzz' instead of 'harfbuzz')
rm -rf harfbuzz
rm -rf libjxl
rm -rf "$WORKDIR"


echo "All done."
