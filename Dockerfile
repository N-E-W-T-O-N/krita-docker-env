ARG BASE_IMAGE=krita-appimage-builder-2204
FROM invent-registry.kde.org/sysadmin/ci-images/${BASE_IMAGE} as base_image
MAINTAINER Dmitry Kazakov <dimula73@gmail.com>

ARG APPIMAGE_UID=1000
ARG APPIMAGE_GID=1000
ARG RENDER_GID=110

USER root

RUN apt-get update && \
    apt-get -y install curl && \
    apt-get -y install emacs-nox && \
    apt-get -y install gitk git-gui && \
    apt-get -y install cmake-curses-gui=3.31.6-0kitware1ubuntu22.04.1 gdb valgrind sysvinit-utils && \
    apt-get -y install nomacs && \
    apt-get -y install mesa-utils && \
    apt-get -y install cpu-checker # for kvm-ok command

RUN update-alternatives --set gcc /usr/bin/gcc-11
RUN update-alternatives --set g++ /usr/bin/g++-11

ENV USRHOME=/home/appimage

RUN chsh -s /bin/bash appimage
RUN groupmod -g ${APPIMAGE_GID} appimage
RUN groupmod -g ${APPIMAGE_GID} appimage
RUN groupadd -g ${RENDER_GID} render
RUN usermod -u ${APPIMAGE_UID} -g ${APPIMAGE_GID} -a -G render appimage

RUN locale-gen en_US.UTF-8

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

USER appimage

CMD tail -f /dev/null

FROM base_image

# a hackish way to copy the deps only if they exist
COPY --chown=appimage:appimage .foo persistent/deps/_install/ ${USRHOME}/appimage-workspace/deps/usr/
ADD --chown=appimage:appimage .foo persistent/qtcreator-package.tar.g[z] ${USRHOME}/
RUN rm ${USRHOME}/appimage-workspace/deps/usr/.foo ${USRHOME}/.foo

CMD tail -f /dev/null
