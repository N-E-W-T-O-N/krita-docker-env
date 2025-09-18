#!/bin/bash

cmake -DCMAKE_INSTALL_PREFIX=${KRITADIR} \
      -DCMAKE_BUILD_TYPE=Release \
      -DKRITA_DEVS=ON \
      -DBUILD_TESTING=TRUE \
      -DHIDE_SAFE_ASSERTS=FALSE \
      -DCMAKE_LIBRARY_PATH=/usr/lib/aarch64-linux-gnu \
      -DQMAKE_EXECUTABLE=/usr/lib/aarch64-linux-gnu/qt5/bin/qmake \
      -DCMAKE_PREFIX_PATH="/usr/lib/aarch64-linux-gnu/qt5;/usr/lib/aarch64-linux-gnu/cmake" \
      -DQT_INSTALL_PLUGINS=/usr/lib/aarch64-linux-gnu/qt5/plugins \
      -DQT_INSTALL_PREFIX=/usr \
      -DFriBidi_INCLUDE_DIR=/usr/include \
      -DFriBidi_LIBRARY=/usr/lib/aarch64-linux-gnu/libfribidi.so \
      -DJPEG_INCLUDE_DIR=/usr/include \
      -DJPEG_LIBRARY=/usr/lib/aarch64-linux-gnu/libjpeg.so \
      -DPYQT_SIP_DIR_OVERRIDE=/home/appimage/appimage-workspace/deps/usr/share/sip \
      $@

#-DCMAKE_REQUIRED_LIBRARIES="-L/usr/lib/aarch64-linux-gnu" "-latomic" \
# -DCMAKE_REQUIRED_LIBRARIES=atomic \
# -DLibAtomic_LIBRARY=/usr/lib/aarch64-linux-gnu/libatomic.so \
# -DCMAKE_EXE_LINKER_FLAGS="-latomic" \
#      -DCMAKE_SHARED_LINKER_FLAGS="-latomic" \
# -DFriBidi_LIBRARY=/usr/lib/aarch64-linux-gnu \
#  -DPYTHON_EXECUTABLE=/usr/bin/python3 \
#  -DQT_QMAKE_EXECUTABLE=/usr/lib/aarch64-linux-gnu/qt5/bin/qmake \
