#!/bin/bash
set -e

export DEBIAN_FRONTEND=noninteractive

# Disable ldconfig during package installation to avoid segfaults
export DPKG_SKIP_LDCONFIG=1

# Setup the various repositories we are going to need for our dependencies

wget -O - https://apt.kitware.com/keys/kitware-archive-latest.asc 2>/dev/null | apt-key add -
add-apt-repository -y ppa:openjdk-r/ppa && apt-add-repository 'deb https://apt.kitware.com/ubuntu/ jammy main'

# Update the system...
apt-get update
apt-get upgrade -y

# Some software demands a newer GCC because they're using C++14 stuff, which is just insane
# We do this after the general system update to ensure it doesn't bring in any unnecessary updates
add-apt-repository -y ppa:ubuntu-toolchain-r/test
apt-get update

# Krita's dependencies (libheif's avif plugins) need Rust 
add-apt-repository -y ppa:ubuntu-mozilla-security/rust-updates
apt-get update
apt-get install -y cargo rustc

# Now install the general dependencies we need for builds

echo "Group 1: Essential build tools"
# Group 1: Essential build tools
apt-get install -y \
# a specific version of CMake to avoid update to CMake 4.0
    cmake=3.31.6-0kitware1ubuntu22.04.1 \
# General requirements for building KDE software
    cmake-data=3.31.6-0kitware1ubuntu22.04.1 \
 # General requirements for building other software
    build-essential gcc-13 g++-13 git-core rsync

echo "Group 2: Development libraries"
# Group 2: Development libraries
apt-get install -y \
  # Needed for some frameworks
    bison gettext \
    automake locale\
    libxml-parser-perl \
    libpq-dev libaio-dev bison gettext gperf \
    # Base system deps
    libnss3-dev libpci-dev libatkmm-1.6-dev libbz2-dev libcap-dev libdbus-1-dev libudev-dev \
    # OpenSSL (1.1.1f) and libgcrypt (1.8.5) libraries 
    libssl-dev libgcrypt-dev

echo "Group 4: Graphics and multimedia"
# Group 4: Graphics and multimedia
apt-get install -y \
     # DRM and openGL libraries
    libdrm-dev libegl1-mesa-dev libgl1-mesa-dev mesa-common-dev \
    # Font libraries (TODO: consider removal)
    libfontconfig1-dev libfreetype6-dev \
    # GNU Scientific Library
    libgsl-dev \
  
# Group 5: Audio libraries
apt-get install -y \
  # GStreamer pugins for Qt Multimedia
    libpulse-dev libasound2-dev \
    gstreamer1.0-pulseaudio gstreamer1.0-plugins-base gstreamer1.0-plugins-good gstreamer1.0-plugins-ugly

# Group 6: GStreamer development
apt-get install -y \
   libgstreamer1.0-dev libgstreamer-plugins-good1.0-dev libgstreamer-plugins-bad1.0-dev libgstreamer-plugins-base1.0-dev


# Group 7: X11 and Wayland libraries  
apt-get install -y \
# XCB Libraries for Qt
  libwayland-dev libicu-dev libxcb-shm0-dev libxinerama-dev libxcb-icccm4-dev libxcb-xinerama0-dev libxcb-image0-dev libxcb-render-util0-dev

# Group 8: More X11 libraries
apt-get install -y \
   libx11-dev libxkbcommon-x11-dev libxcb-glx0-dev libxcb-keysyms1-dev libxcb-util0-dev libxcb-res0-dev libxcb1-dev

# Group 9: Additional X11 components
apt-get install -y \
   libxcomposite-dev libxcursor-dev libxdamage-dev libxext-dev libxfixes-dev libxi-dev libxrandr-dev libxrender-dev
  
# Group 10: XCB components
apt-get install -y \

  libxcb-randr0-dev libxcb-shape0-dev libxcb-xfixes0-dev libxcb-sync-dev libxcb-xinput-dev libxss-dev libxtst-dev \
  # for Qt6's XCB-QPA module
  libxcb-cursor-dev
  

# Group 11: Input and misc
apt-get install -y \
  # for Qt6's Wayland-QPA module
  libinput-dev \
  # for Wayland libraries
  libxml2-dev \
  # Krita AppImage Python extra dependencies
  libffi-dev \
  # Other
  flex \
  # cppcheck is necessary for the CI
  cppcheck \
  # packages necessary by appimage build tools
  file squashfs-tools patchelf

# Install Python tools
apt-get install --yes ccache python3-yaml python3-pip python3-packaging python3-lxml python3-clint python3-venv openbox menu xvfb dbus-x11 graphviz

# Krita's dependencies (libheif's avif plugins) need meson and ninja, both aren't available in binary form for 22.04
python3 -m pip install meson ninja python-gitlab gcovr==5.0 cppcheck-codequality graphviz

# See bug for gcovr: https://github.com/gcovr/gcovr/issues/583
python3 -m pip install python-gitlab gcovr==5.0 cppcheck-codequality graphviz


update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-13 20
update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-11 10
update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-13 20
update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-11 10
update-alternatives --install /usr/bin/gcov gcov /usr/bin/gcov-13 20
update-alternatives --install /usr/bin/gcov gcov /usr/bin/gcov-11 10
update-alternatives --install /usr/bin/gcov-dump gcov-dump /usr/bin/gcov-dump-13 20
update-alternatives --install /usr/bin/gcov-dump gcov-dump /usr/bin/gcov-dump-11 10
update-alternatives --install /usr/bin/gcov-tool gcov-tool /usr/bin/gcov-tool-13 20
update-alternatives --install /usr/bin/gcov-tool gcov-tool /usr/bin/gcov-tool-11 10

# Install Gitlab Runner
wget -q -O /usr/local/bin/gitlab-runner https://s3.dualstack.us-east-1.amazonaws.com/gitlab-runner-downloads/latest/binaries/gitlab-runner-linux-arm64
chmod +x /usr/local/bin/gitlab-runner

# Setup build and cache folders
mkdir /builds /cache
chown 1000:1000 /builds /cache

# Clean up to reduce image size
apt-get -qq clean

# Force ldconfig to run now in a controlled way
echo "Running ldconfig manually..."
ldconfig || echo "ldconfig completed with warnings"
