ARG BASE_IMAGE=ubuntu:22.04
FROM ${BASE_IMAGE} AS base_image
LABEL maintainer="Dmitry Kazakov <dimula73@gmail.com>"

ARG APPIMAGE_UID=1000
ARG APPIMAGE_GID=1000
ARG RENDER_GID=110

USER root


RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    # Build & Core Tools
    build-essential cmake meson ninja-build \
    # The version for cmake-curses-gui was pinned in your original command.
    # This might fail if the repository or version is no longer available.
    # Consider removing the version pin if you encounter issues.
    cmake-curses-gui=4.1.1-0kitware1ubuntu22.04.1 \
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
    python3-sip-dev \
    # KDE Frameworks 5
    libkf5completion-dev \
    libkf5config-dev \
    libkf5coreaddons-dev \
    libkf5guiaddons-dev \
    libkf5i18n-dev \
    libkf5itemmodels-dev \
    libkf5itemviews-dev \
    libkf5kdcraw-dev \
    libkf5widgetsaddons-dev \
    libkf5windowsystem-dev \
    # Qt5 Modules
    qt5-qmake qtbase5-dev qtdeclarative5-dev qtquickcontrols2-5-dev qttools5-dev \
    qttools5-dev-tools libqt5multimedia5-plugins qml-module-qtmultimedia qtmultimedia5-dev \ 
    # libqt5multimedia5-dev \
    libqt5multimediawidgets5 libqt5opengl5-dev libqt5printsupport5  \
    libqt5svg5-dev libqt5webkit5-dev libqt5x11extras5-dev libqt5xmlpatterns5-dev \
    # Image & Graphics Libraries
    libbrotli-dev libexiv2-dev libgif-dev \
    libheif-dev libjpeg-dev liblcms2-dev \
    libmypaint-dev libopencolorio-dev \
    libopenexr-dev libopenjp2-7-dev \
    libpng-dev libpoppler-qt5-dev \
    libtiff5-dev libwebp-dev \
    # Font Libraries (we'll build newer harfbuzz from source)
    libfontconfig1-dev libfreetype6-dev \
    libharfbuzz-dev libunibreak-dev \
    # X11 Libraries
    libx11-dev libxext-dev libxfixes-dev libxi-dev libxrandr-dev libxrender-dev \
    # General Libraries
    libboost-system-dev libeigen3-dev \
    libfftw3-dev libgsl-dev libmlt-dev \
    libquazip5-dev libsdl2-dev zlib1g-dev \
    ragel gtk-doc-tools libglib2.0-dev libcairo2-dev \
    # --- Cleanup ---
    && rm -rf /var/lib/apt/lists/* &&  apt-get clean && apt-get autoclean

# Build libjxl from source (v0.11.x) - separate stage for caching
FROM base_image AS libjxl_builder
WORKDIR /tmp/build
RUN echo "Build libjxl from source ...."
RUN git clone --branch v0.11.x --depth 1 --recursive \
    https://github.com/libjxl/libjxl.git && \
    cd libjxl && \
    mkdir build && cd build && \
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
    .. && \
    make -j$(nproc) && \
    make install && \
    # Cleanup build artifacts
    cd / && rm -rf /tmp/build

# Build HarfBuzz from source (11.5.0) - separate stage for caching  
FROM libjxl_builder AS harfbuzz_builder
WORKDIR /tmp/build
RUN echo "Build harfbuzz from source ...."
RUN git clone --branch 11.5.0 --depth 1 \
    https://github.com/harfbuzz/harfbuzz.git && \
    cd harfbuzz && \
    meson setup build \
    --buildtype=release \
    --prefix=/usr/local \
    --default-library=shared \
    -Dtests=disabled \
    -Ddocs=disabled \
    -Dbenchmark=disabled \
    -Dintrospection=disabled \
    -Dicu=disabled && \
    ninja -C build -j$(nproc) && \
    ninja -C build install && \
    # Update library cache
    ldconfig && \
    # Cleanup build artifacts  
    cd / && rm -rf /tmp/build

# Continue with main image setup
FROM harfbuzz_builder AS final_image


#RUN python3 -m pip install sipbuild sipconfig

ENV USRHOME=/home/appimage

RUN chsh -s /bin/bash appimage && \
    groupmod -g ${APPIMAGE_GID} appimage && \
    groupadd -g ${RENDER_GID} render && \
    usermod -u ${APPIMAGE_UID} -g ${APPIMAGE_GID} -a -G render appimage && \
    locale-gen en_US.UTF-8

RUN mkdir /tmp/xdg-runtime && \
    chown appimage:appimage /tmp/xdg-runtime

RUN echo 'export LC_ALL=en_US.UTF-8' >> ${USRHOME}/.bashrc && \
    echo 'export LANG=en_US.UTF-8'  >> ${USRHOME}/.bashrc && \
    echo "export PS1='\u@\h:\w>'"  >> ${USRHOME}/.bashrc && \
    echo 'source ~/devenv.inc' >> ${USRHOME}/.bashrc && \
    echo 'prepend PATH ~/bin/' >> ${USRHOME}/.bashrc

RUN mkdir -p ${USRHOME}/appimage-workspace/krita.appdir/usr && \
    mkdir -p ${USRHOME}/appimage-workspace/krita-build && \
    mkdir -p ${USRHOME}/appimage-workspace/deps/usr && \
    mkdir -p ${USRHOME}/bin

COPY ./default-home/devenv.inc \
    ./default-home/.bash_aliases \
    ${USRHOME}/

COPY ./default-home/run_cmake.sh \
    ./default-home/build_krita_appimage.sh \
    ${USRHOME}/bin/

RUN chown appimage:appimage -R ${USRHOME}/
RUN chmod a+rwx /tmp

RUN git config --global http.postBuffer 1024M

USER appimage

CMD ["tail", "-f", "/dev/null"]

# Final layer with deps copy (if they exist)
FROM final_image

COPY --chown=appimage:appimage .foo persistent/deps/_install/ ${USRHOME}/appimage-workspace/deps/usr/
ADD --chown=appimage:appimage .foo persistent/qtcreator-package.tar.g[z] ${USRHOME}/
RUN rm ${USRHOME}/appimage-workspace/deps/usr/.foo ${USRHOME}/.foo
CMD ["tail", "-f", "/dev/null"]
