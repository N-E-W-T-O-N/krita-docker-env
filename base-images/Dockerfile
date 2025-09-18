FROM ubuntu:24.04

LABEL Description="KDE Appimage Base"
LABEL org.opencontainers.image.authors="KDE Sysadmin <sysadmin@kde.org>,Dmitry Kazakov <dimula73@gmail.com>"

# Start off as root
USER root

# Timezone setup
# This needs to happen before apt is invoked as that will trigger the setup of tzdata
ENV TZ=Etc/UTC
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# Setup a user account for everything else to be done under
# Also needs to be done beforehand to ensure that /builds and /cache can be assigned to the user in the build script
#RUN useradd -d /home/appimage/ -u 1000 --user-group --create-home -G video appimage
RUN useradd -d /home/appimage/ --user-group --create-home -G video appimage
RUN apt-get update && \
    apt-get install -y apt-transport-https ca-certificates gnupg software-properties-common wget locales && \
# Get locales in order
    locale-gen en_US en_US.UTF-8 en_NZ.UTF-8

# System provisioning shared with the VM build
COPY build.sh /var/lib/ci-files/
RUN chmod +x /var/lib/ci-files/build.sh

# Set environment variables to avoid ldconfig issues during build
ENV DPKG_SKIP_LDCONFIG=1

# Run the build script with error handling
RUN /var/lib/ci-files/build.sh; \
    # Force a final ldconfig run after all packages are installed
    ldconfig 2>/dev/null || true; \
    # Clean up
    apt-get -qq clean

# Certain X11 based software is very particular about permissions and ownership around /tmp/.X11-unix/ so ensure this is right
# Certain X11 based software is very particular about permissions around /tmp/.X11-unix/
RUN mkdir /tmp/.X11-unix/ && chown root:root /tmp/.X11-unix/ && chmod 1777 /tmp/.X11-unix/

# For D-Bus to be willing to start it needs a Machine ID
RUN dbus-uuidgen > /etc/machine-id

# Make sure SSHD will be able to startup
RUN mkdir /var/run/sshd/


# Switch over to our new user and add in the utilities needed for appimage builds
USER appimage


 
