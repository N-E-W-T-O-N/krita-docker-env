prepend() { [ -d "$2" ] && eval $1=\"$2\$\{$1:+':'\$$1\}\" && export $1 ; }

export KRITADIR=/home/appimage/appimage-workspace/krita.appdir/usr
export DEPSDIR=/home/appimage/appimage-workspace/deps/usr
#export QML2_IMPORT_PATH=$KRITADIR/lib/x86_64-linux-gnu/qml
export QML2_IMPORT_PATH=$KRITADIR/lib/aarch64-linux-gnu/qml

prepend PATH $KRITADIR/bin
prepend LD_LIBRARY_PATH $KRITADIR/lib64
prepend LD_LIBRARY_PATH $KRITADIR/lib
#prepend XDG_DATA_DIRS $KRITADIR/share
prepend PKG_CONFIG_PATH $KRITADIR/lib64/pkgconfig
prepend PKG_CONFIG_PATH $KRITADIR/lib/pkgconfig

prepend PATH $DEPSDIR/bin
prepend LD_LIBRARY_PATH $DEPSDIR/lib64
prepend LD_LIBRARY_PATH $DEPSDIR/lib
#prepend LD_LIBRARY_PATH $DEPSDIR/lib/x86_64-linux-gnu
prepend LD_LIBRARY_PATH $DEPSDIR/lib/aarch64-linux-gnu
#prepend XDG_DATA_DIRS $DEPSDIR/share
prepend PKG_CONFIG_PATH $DEPSDIR/lib64/pkgconfig
prepend PKG_CONFIG_PATH $DEPSDIR/lib/pkgconfig

prepend CMAKE_PREFIX_PATH $DEPSDIR

#prepend PYTHONPATH $DEPSDIR/lib/python3.5/
prepend PYTHONPATH $DEPSDIR/sip

prepend PATH ~/tools/bin

prepend EXTERNALS_DOWNLOAD_DIR=/home/appimage/persistent/downloads
mkdir -p /home/appimage/persistent/downloads

# Disable leak checks in case ASAN is used.
# It takes a lot of time to finalize the leaks 
# and we usually just check for invalid access
export ASAN_OPTIONS=detect_leaks=0

# Add AppImage simulation variables to make sure MLT library works
# fine

if [[ -z $ANDROID_HOME ]]; then
   export APPIMAGE=1
   export APPDIR=/home/appimage/appimage-workspace/deps/
fi
