#!/bin/bash

function tryCreatePulseaudioSocket {
    if [[ -e /run/user/$UID/pulse/native ]]; then
        echo "### Trying to connect to existing socket pulseaudio socket..."
        INTERNAL_PULSEAUDIO_SOCKET=/run/user/$UID/pulse/native
    elif [[ ! -e /tmp/pulseaudio-docker.socket ]]; then
        echo "### Creating a pulseaudio socket..."
        pactl load-module module-native-protocol-unix socket=/tmp/pulseaudio-docker.socket
        INTERNAL_PULSEAUDIO_SOCKET=/tmp/pulseaudio-docker.socket
    fi

    if [[ ! -e /tmp/pulseaudio.client.conf ]]; then
        cat <<EOF > /tmp/pulseaudio.client.conf
default-server = unix:/tmp/pulseaudio-docker.socket
# Prevent a server running in the container
autospawn = no
daemon-binary = /bin/true
# Prevent the use of shared memory
enable-shm = false
EOF
    fi

    echo "### Using pulseaudio socket: $INTERNAL_PULSEAUDIO_SOCKET"
}