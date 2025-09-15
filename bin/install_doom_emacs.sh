#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source ${DIR}/find_default_container_file.inc

container_name=$(parseContainerArgs $*)
if [ -z ${container_name} ]; then
    exit 1
fi

tryStartContainer $container_name

function run {
    ${DOCKER_BINARY} exec -ti ${container_name} sh -c "cd ~; $*"
}

function run_root {
    ${DOCKER_BINARY} exec -u root -ti ${container_name} sh -c "cd ~; $*"
}

CLANG_VERSION=20.1.8
RIPGREP_VERSION=14.1.1
EMACS_PACKAGE=emacs27

run_root apt-get remove --auto-remove -yy emacs24-nox
run_root apt-get install unzip
run wget https://github.com/clangd/clangd/releases/download/${CLANG_VERSION}/clangd-linux-${CLANG_VERSION}.zip
run unzip clangd-linux-${CLANG_VERSION}.zip
run rm clangd-linux-${CLANG_VERSION}.zip
run "echo prepend PATH ~/clangd_${CLANG_VERSION}/bin/ >> ~/devenv.inc"

run_root wget https://github.com/BurntSushi/ripgrep/releases/download/${RIPGREP_VERSION}/ripgrep_${RIPGREP_VERSION}_arm64.deb
run_root dpkg -i ripgrep_${RIPGREP_VERSION}_arm64.deb
run_root rm ripgrep_${RIPGREP_VERSION}_arm64.deb

run_root add-apt-repository -yy ppa:kelleyk/emacs
run_root apt-get update
run_root apt-get install -yy ${EMACS_PACKAGE}

run "git clone --depth 1 https://github.com/hlissner/doom-emacs ~/.emacs.d"
run "~/.emacs.d/bin/doom install"

# cmake -DCMAKE_EXPORT_COMPILE_COMMANDS=1
