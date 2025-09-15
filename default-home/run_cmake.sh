#!/bin/bash

cmake -DCMAKE_INSTALL_PREFIX=${KRITADIR} \
      -DCMAKE_BUILD_TYPE=Release \
      -DKRITA_DEVS=ON \
      -DBUILD_TESTING=TRUE \
      -DHIDE_SAFE_ASSERTS=FALSE \
      -DQMAKE_EXECUTABLE=/usr/lib/aarch64-linux-gnu/qt5/bin/qmake \
      -DCMAKE_PREFIX_PATH="/usr/lib/aarch64-linux-gnu/qt5;/usr/lib/aarch64-linux-gnu/cmake" \
      -DQT_INSTALL_PLUGINS=/usr/lib/aarch64-linux-gnu/qt5/plugins \
      -DQT_INSTALL_PREFIX=/usr \
      -DPYQT_SIP_DIR_OVERRIDE=/home/appimage/appimage-workspace/deps/usr/share/sip \
      $@

#  -DPYTHON_EXECUTABLE=/usr/bin/python3 \
#  -DQT_QMAKE_EXECUTABLE=/usr/lib/aarch64-linux-gnu/qt5/bin/qmake \
