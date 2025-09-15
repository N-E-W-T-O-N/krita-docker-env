#!/bin/bash

function tryCreatePulseaudioSocket {

    echo "tryCreatePulseaudioSocket"    

    if [[ -e /run/user/$UID/pulse/native ]]; then
        echo "### Trying to connect to existing socket pulseaudio socket..."
        INTERNAL_PULSEAUDIO_SOCKET=/run/user/$UID/pulse/native
    elif [[ ! -e /tmp/pulseaudio-docker.socket ]]; then
        echo "### Creating a pulseaudio socket..."
        pactl load-module module-native-protocol-unix socket=/tmp/pulseaudio-docker.socket
        INTERNAL_PULSEAUDIO_SOCKET=/tmp/pulseaudio-docker.socket
    fi

    if [[ ! -S ${INTERNAL_PULSEAUDIO_SOCKET} ]]; then
        INTERNAL_PULSEAUDIO_SOCKET=
    fi

    # Add this to your build_image or run_container script
    echo "### Ensuring required files exist..."
    
    if [[ -n ${INTERNAL_PULSEAUDIO_SOCKET} && ! -e /tmp/pulseaudio.client.conf ]]; then
        cat <<EOF > /tmp/pulseaudio.client.conf
default-server = unix:/tmp/pulseaudio-docker.socket
# Prevent a server running in the container
autospawn = no
daemon-binary = /bin/true
# Prevent the use of shared memory
enable-shm = false
EOF
    fi

    if [[ -n ${INTERNAL_PULSEAUDIO_SOCKET} ]]; then
        echo "### Using pulseaudio socket: $INTERNAL_PULSEAUDIO_SOCKET"
    else
        echo "### Pulseaudio socket was not found!"
    fi
}