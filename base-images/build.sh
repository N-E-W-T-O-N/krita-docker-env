#!/bin/bash
set -e

export DEBIAN_FRONTEND=noninteractive

# --- OPTIMIZATION: Add all repositories first ---
echo "## Adding APT repositories..."

# Disable ldconfig during package installation to avoid segfaults
export DPKG_SKIP_LDCONFIG=1

# Setup the various repositories we are going to need for our dependencies

# Kitware for up-to-date CMake
wget -O - https://apt.kitware.com/keys/kitware-archive-latest.asc | gpg --dearmor -o /usr/share/keyrings/kitware-archive-keyring.gpg
# FIX #1: Changed 'jammy' to 'noble' to match Ubuntu 24.04
echo "deb [signed-by=/usr/share/keyrings/kitware-archive-keyring.gpg] https://apt.kitware.com/ubuntu/ noble main" | tee /etc/apt/sources.list.d/kitware.list > /dev/null

# Other PPAs
add-apt-repository -y ppa:openjdk-r/ppa

# Update the system...
apt-get update
apt-get upgrade -y

# Some software demands a newer GCC because they're using C++14 stuff, which is just insane
# We do this after the general system update to ensure it doesn't bring in any unnecessary updates
add-apt-repository -y ppa:ubuntu-toolchain-r/test
# add-apt-repository -y ppa:ubuntu-mozilla-security/rust-updates

# --- OPTIMIZATION: Run a single, consolidated update and install ---
echo "## Updating system and installing all APT dependencies..."
apt-get update
apt-get upgrade -y

echo "Group 1: Essential build tools"
# Group 1: 

apt-get install -y \
    # Build tools & Base deps
    build-essential \
    # FIX #2: Removed specific version pin for cmake, which was for Ubuntu 22.04
    cmake \
    cmake-data \
    gcc-13 \
    g++-13 \
    git-core \
     # General requirements for building other software
    build-essential
    rsync \
    bison \
    gettext \
    automake \
    gperf \
    cppcheck \
    file \
    squashfs-tools \
    patchelf \
    flex \
    # Rust toolchain
    cargo \
    rustc \
    # Libraries
    libpq-dev \
    libaio-dev \
    libnss3-dev \
    libpci-dev \
    libatkmm-1.6-dev \
    libbz2-dev \
    libcap-dev \
    libdbus-1-dev \
    libudev-dev \
    libssl-dev \
    libgcrypt-dev \
    libdrm-dev \
    libegl1-mesa-dev \
    libgl1-mesa-dev \
    mesa-common-dev \
    libfontconfig1-dev \
    libfreetype6-dev \
    libgsl-dev \
    libpulse-dev \
    libasound2-dev \
    libgstreamer1.0-dev \
    libgstreamer-plugins-good1.0-dev \
    libgstreamer-plugins-bad1.0-dev \
    libgstreamer-plugins-base1.0-dev \
    libwayland-dev \
    libicu-dev \
    libxcb-shm0-dev \
    libxinerama-dev \
    libxcb-icccm4-dev \
    libxcb-xinerama0-dev \
    libxcb-image0-dev \
    libxcb-render-util0-dev \
    libx11-dev \
    libxkbcommon-x11-dev \
    libxcb-glx0-dev \
    libxcb-keysyms1-dev \
    libxcb-util0-dev \
    libxcb-res0-dev \
    libxcb1-dev \
    libxcomposite-dev \
    libxcursor-dev \
    libxdamage-dev \
    libxext-dev \
    libxfixes-dev \
    libxi-dev \
    libxrandr-dev \
    libxrender-dev \
    libxcb-randr0-dev \
    libxcb-shape0-dev \
    libxcb-xfixes0-dev \
    libxcb-sync-dev \
    libxcb-xinput-dev \
    libxss-dev \
    libxtst-dev \
    libxcb-cursor-dev \
    libinput-dev \
    libxml2-dev \
    libffi-dev \
    # GStreamer plugins
    gstreamer1.0-pulseaudio \
    gstreamer1.0-plugins-base \
    gstreamer1.0-plugins-good \
    gstreamer1.0-plugins-ugly \
    # Python tools
    ccache \
    python3-yaml \
    python3-pip \
    python3-packaging \
    python3-lxml \
    python3-clint \
    python3-venv \
    # GUI/X11 tools for AppImage
    openbox \
    menu \
    xvfb \
    dbus-x11 \
    graphviz

# --- Python packages ---
echo "## Installing Python (pip) dependencies..."
# OPTIMIZATION: Combined and removed duplicate install
python3 -m pip install meson ninja python-gitlab gcovr==5.0 cppcheck-codequality graphviz

# --- System configuration ---
echo "## Configuring system alternatives..."
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

# --- Install Gitlab Runner ---
echo "## Installing GitLab Runner..."
# OPTIMIZATION: Detect architecture instead of hardcoding arm64
ARCH=$(dpkg --print-architecture)
wget -q -O /usr/local/bin/gitlab-runner https://s3.dualstack.us-east-1.amazonaws.com/gitlab-runner-downloads/latest/binaries/gitlab-runner-linux-${ARCH}
chmod +x /usr/local/bin/gitlab-runner

# --- Final setup and cleanup ---
echo "## Finalizing setup..."
mkdir /builds /cache
# FIX #3: Changed owner to the correct user 'appimage' (UID 1001)
chown appimage:appimage /builds /cache

# Clean up to reduce image size
apt-get -qq clean
rm -rf /var/lib/apt/lists/*

# Force ldconfig to run now
echo "Running ldconfig manually..."
ldconfig || true