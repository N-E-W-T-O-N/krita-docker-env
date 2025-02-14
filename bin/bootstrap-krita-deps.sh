#!/bin/bash

set -e

usage=\
"Usage: $(basename "$0") [OPTION]...\n
Bootstrap deps for building the krita in the docker image\n
\n
where:\n
    -h,      --help              show this help text\n
    -a ARCH, --android=ARCH      target architecture ('x86_64', 'armeabi-v7a', 'arm64-v8a')\n
    -p DIR,  --prefix=DIR        working directory for the environment setup\n
    -b BRANCH,  --branch=BRANCH  a custom branch for fetching Krita deps\n
\n
"

TARGET_ANDROID_ABI_ARG=
WORK_DIR=./persistent/deps/
BRANCH=

# Call getopt to validate the provided input.
options=$(getopt -o "ha:p:b:" --long "help android: prefix: branch:" -- "$@")
[ $? -eq 0 ] || {
    echo "Incorrect options provided"
    exit 1
}
eval set -- "$options"
while true; do
    case "$1" in
    -b | --branch)
        BRANCH="$2"
        ;;
    -a | --android)
        TARGET_ANDROID_ABI_ARG="--android-abi $2"
        ;;
    -p | --prefix)
        WORK_DIR=$2
        ;;
    -h | --help)
        echo -e $usage >&2
        exit 1
        ;;
    --)
        shift
        break
        ;;
    esac
    shift
done

set -ex

if [ ! -d $WORK_DIR ]; then
    mkdir -p $WORK_DIR
fi

BRANCH_ARG=
if [ -n "$BRANCH" ]; then
    BRANCH_ARG="-b $BRANCH"
fi

if [ ! -d $WORK_DIR/_install ]; then
    (
        cd $WORK_DIR

        if [ ! -d ./krita-deps-management ]; then
            git clone https://invent.kde.org/packaging/krita-deps-management.git $BRANCH_ARG
        else
            (
                cd ./krita-deps-management
                if [ -n "$BRANCH" ]; then
                    git checkout $BRANCH
                fi
                git pull
            )
        fi
        if [ ! -d ./krita-deps-management/ci-utilities ]; then
            git clone https://invent.kde.org/packaging/krita-ci-utilities.git krita-deps-management/ci-utilities
        else
            (
                cd ./krita-deps-management/ci-utilities
                git pull
            )
        fi
        python3 -m venv PythonEnv --upgrade-deps
        . PythonEnv/bin/activate
        python -m pip install -r krita-deps-management/requirements.txt
        python krita-deps-management/tools/setup-env.py --full-krita-env -v PythonEnv $TARGET_ANDROID_ABI_ARG $BRANCH_ARG
    )
fi
