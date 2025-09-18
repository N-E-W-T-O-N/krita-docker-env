ARG BASE_IMAGE=ubuntu:24.04
FROM ${BASE_IMAGE} AS base_image
LABEL maintainer="Dmitry Kazakov <dimula73@gmail.com>"

#RUN echo "Using base image: ${base_image}"

# Accept build arguments for user/group IDs, with sane defaults
ARG APPIMAGE_UID=1000
ARG APPIMAGE_GID=1000
ARG RENDER_GID=110

USER root

RUN apt-get update && \
    apt-get dist-upgrade -y && \
    apt-get install -y --no-install-recommends \
    # Build & Core Tools
    build-essential cmake meson ninja-build locales \
    # The version for cmake-curses-gui was pinned in your original command.
    # This might fail if the repository or version is no longer available.
    # Consider removing the version pin if you encounter issues.
    #cmake-curses-gui=4.1.1-0kitware1ubuntu22.04.1 \
    cmake-curses-gui \
    # for kvm-ok command
    cpu-checker curl \  
    emacs-nox extra-cmake-modules g++ gcc gdb git \
    git-gui gitk mesa-utils nomacs pkg-config sysvinit-utils valgrind \
    # Python
    python3-dev \
    python3-pip \
    python3-pyqt5 \
    #    python3-pyqt5.qtcore \
    #    python3-pyqt5.qtgui \
    #    python3-pyqt5.qtwidgets \
    python3-sip \
    python3-sip-dev python3-pyqt5 python3-setuptools \
    # KDE Frameworks 5
    libkf5completion-dev \
    libkf5config-dev \
    libkf5config-dev-bin \
    libkf5coreaddons-dev \
    libkf5configcore5 \
    libkf5configgui5 \
    libkf5configqml5 \
    libkf5guiaddons-dev \
    libkf5i18n-dev \
    libkf5itemmodels-dev \
    libkf5itemviews-dev \
    libkf5kdcraw-dev \
    libkf5widgetsaddons-dev \
    libkf5windowsystem-dev \
    # Qt5 Modules
    qt5-qmake qtbase5-dev qtdeclarative5-dev qtquickcontrols2-5-dev qttools5-dev qtbase5-dev-tools  \
    qttools5-dev-tools libqt5multimedia5-plugins qml-module-qtmultimedia qtmultimedia5-dev \
    # libqt5multimedia5-dev \
    libqt5multimediawidgets5 libqt5opengl5-dev libqt5printsupport5 \
    libqt5svg5-dev libqt5webkit5-dev libqt5x11extras5-dev libqt5xmlpatterns5-dev \
    # Image & Graphics Libraries
    libbrotli-dev libexiv2-dev libgif-dev \
    libheif-dev libjpeg-dev liblcms2-dev \
    libmypaint-dev libopencolorio-dev \
    libopenexr-dev libopenjp2-7-dev \
    libpng-dev libpoppler-qt5-dev \
    libunibreak5 libunibreak-dev libxss-dev \
    # JPEG XL Image Coding System
    libjxl0.7  libjxl-dev \ 
    libtiff5-dev   libtiff6 libtiff-dev libwebp-dev autoconf automake libtool pkg-config \
    # Font Libraries (we'll build newer harfbuzz from source)
    libfontconfig1-dev libfreetype6-dev \
    libharfbuzz-dev libharfbuzz0b libharfbuzz-subset0\
    # X11 Libraries
    libx11-dev libxext-dev libxfixes-dev libxi-dev libxrandr-dev libxrender-dev \
    libice6 libice-dev libxkbcommon-dev libxkbcommon-x11-0 \
    # General Libraries
    libboost-system-dev libeigen3-dev nano libatomic1 libatomic-ops-dev libatomic1-arm64-cross libavahi-client3 libavahi-common3\
    libfftw3-dev libgsl-dev libmlt-dev libblas3\
    libquazip5-dev libsdl2-dev zlib1g-dev libsm-dev\
    ragel gtk-doc-tools libglib2.0-dev libcairo2-dev  libxsimd-dev \
    # --- Cleanup ---
    && rm -rf /var/lib/apt/lists/* &&  apt-get -qq clean

# Install Rust (non-interactive)
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain 1.89.0 --profile minimal
ENV PATH="/root/.cargo/bin:${PATH}"

#RUN python3 -m pip install sipbuild sipconfig
#RUN ln -s /usr/lib/aarch64-linux-gnu/libatomic.so.1.2.0 /usr/lib/aarch64-linux-gnu/libatomic.so

# CORRECTED BLOCK
ENV USRHOME=/home/appimage

# Create group and user only if they do not already exist
RUN (getent group ${RENDER_GID} || groupadd -g ${RENDER_GID} render) && \
    (getent group ${APPIMAGE_GID} || groupadd -g ${APPIMAGE_GID} appimage) && \
    (getent passwd ${APPIMAGE_UID} || useradd -u ${APPIMAGE_UID} -g ${APPIMAGE_GID} -G render,video,sudo -s /bin/bash --create-home appimage) && \
    # Generate locale
    locale-gen en_US.UTF-8

# Prepare runtime directories and set ownership
RUN mkdir /tmp/xdg-runtime && \
    chown appimage:appimage /tmp/xdg-runtime

# Setup environment for the appimage user
RUN echo 'export LC_ALL=en_US.UTF-8' >> ${USRHOME}/.bashrc && \
    echo 'export LANG=en_US.UTF-8'  >> ${USRHOME}/.bashrc && \
    echo "export PS1='\u@\h:\w>'"  >> ${USRHOME}/.bashrc && \
    echo 'source ~/devenv.inc' >> ${USRHOME}/.bashrc && \
    echo 'prepend PATH ~/bin/' >> ${USRHOME}/.bashrc

# Create workspace directories with correct ownership
RUN mkdir -p ${USRHOME}/appimage-workspace/krita.appdir/usr && \
    mkdir -p ${USRHOME}/appimage-workspace/krita-build && \
    mkdir -p ${USRHOME}/appimage-workspace/deps/usr && \
    mkdir -p ${USRHOME}/bin

# Copy default home files and scripts
COPY ./default-home/devenv.inc \
    ./default-home/.bash_aliases \
    ${USRHOME}/

COPY ./default-home/run_cmake.sh \
    ./default-home/build_krita_appimage.sh \
    ./default-home/install_extra.sh \
    ${USRHOME}/bin/

# Set ownership and permissions
RUN chown appimage:appimage -R ${USRHOME}/
RUN chmod a+rwx /tmp

RUN git config --global http.postBuffer 1024M

RUN apt-get update && \
    apt-get dist-upgrade -y 

# Switch to non-root user
USER appimage

CMD ["tail", "-f", "/dev/null"]

# Final layer with deps copy if applicable
FROM base_image

COPY --chown=appimage:appimage .foo persistent/deps/_install/ ${USRHOME}/appimage-workspace/deps/usr/
ADD --chown=appimage:appimage .foo persistent/qtcreator-package.tar.g[z] ${USRHOME}/
RUN rm ${USRHOME}/appimage-workspace/deps/usr/.foo ${USRHOME}/.foo

CMD ["tail", "-f", "/dev/null"]
