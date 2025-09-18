#!/bin/bash

function tryCreatePulseaudioSocket {
    echo "tryCreatePulseaudioSocket"

    INTERNAL_PULSEAUDIO_SOCKET=""
    echo "### Trying to connect to existing socket pulseaudio socket..."
    # 1. Check if PulseAudio is already running and socket exists
    if [[ -S /run/user/$UID/pulse/native ]]; then
        echo "### Found existing pulseaudio socket"
        INTERNAL_PULSEAUDIO_SOCKET=/run/user/$UID/pulse/native
    else
        # 2. Try to start PulseAudio daemon if installed
        if command -v pulseaudio >/dev/null 2>&1; then
            echo "### Starting pulseaudio daemon..."
            pulseaudio --start --exit-idle-time=-1 --daemonize
            sleep 1
            if [[ -S /run/user/$UID/pulse/native ]]; then
                echo "### Pulseaudio socket created"
                INTERNAL_PULSEAUDIO_SOCKET=/run/user/$UID/pulse/native
            fi
        fi
    fi

    # 3. If still no socket, fall back to dummy config
    if [[ -z "$INTERNAL_PULSEAUDIO_SOCKET" ]]; then
        echo "### Pulseaudio socket was not found, falling back to dummy (no-audio)"
        INTERNAL_PULSEAUDIO_SOCKET=""
        cat <<EOF > /tmp/pulseaudio.client.conf
autospawn = no
daemon-binary = /bin/true
enable-shm = false
EOF
    else
        # Write client.conf pointing to real socket
        cat <<EOF > /tmp/pulseaudio.client.conf
default-server = unix:$INTERNAL_PULSEAUDIO_SOCKET
autospawn = no
daemon-binary = /bin/true
enable-shm = false
EOF
    fi

    if [[ -n "$INTERNAL_PULSEAUDIO_SOCKET" ]]; then
        echo "### Using pulseaudio socket: $INTERNAL_PULSEAUDIO_SOCKET"
    else
        echo "### Running with no audio support"
    fi
}
