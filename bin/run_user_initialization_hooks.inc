#!/bin/bash

function runUserInitializationHooks {
    local DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
    local HOOKSDIR=$(realpath "$DIR/../user-hooks.d")
    
    echo "Sending CMake to build path"
    if [[ -d $HOOKSDIR ]]; then
        for file in $(find "$HOOKSDIR" -type f -name "*.sh" -executable | sort); do
           echo "Running user hook: $file"
            "$file"
        done
    fi

}
