#!/bin/bash -e
# Title: spm
# Description: Downloads and installs AppImages and precompiled tar archives.  Can also upgrade and remove installed packages.
# Dependencies: GNU coreutils, tar, wget
# Author: simonizor
# Website: http://www.simonizor.gq
# License: GPL v2.0 only
# Script for building releases of appimagebuild

BUILD_DIR="/run/media/simonizor/0d208b29-3b29-4ffc-99be-1043b9f3c258/github/all-releases"
VERSION="0.0.3"
mkdir -p "$BUILD_DIR"/deps/extracted
mkdir "$BUILD_DIR"/appimagebuild.AppDir

debiangetlatestdebfunc () {
    DEB_RELEASE="$1"
    DEB_ARCH="$2"
    DEB_NAME="$3"
    LATEST_DEB_URL="$(wget "https://packages.debian.org/$DEB_RELEASE/$DEB_ARCH/$DEB_NAME/download" -qO - | grep "<li>*..*$DEB_ARCH.deb" | cut -f2 -d'"' | head -n 1)"
    wget --no-verbose --read-timeout=30 "$LATEST_DEB_URL" -O "$BUILD_DIR"/deps/"$DEB_NAME".deb
}
debiangetlatestdebfunc "buster" amd64 "wget"
debiangetlatestdebfunc "buster" amd64 "libgnutls30"
debiangetlatestdebfunc "buster" amd64 "libhogweed4"
debiangetlatestdebfunc "buster" amd64 "libidn2-0"
debiangetlatestdebfunc "buster" amd64 "libunistring2"
debiangetlatestdebfunc "buster" amd64 "libnettle6"
debiangetlatestdebfunc "buster" amd64 "libpcre3"
debiangetlatestdebfunc "buster" amd64 "libpsl5"
debiangetlatestdebfunc "buster" amd64 "libuuid1"
debiangetlatestdebfunc "buster" amd64 "zlib1g"
debiangetlatestdebfunc "buster" amd64 "binutils"
debiangetlatestdebfunc "buster" amd64 "git"
debiangetlatestdebfunc "buster" amd64 "libcurl3-gnutls"
debiangetlatestdebfunc "buster" all "liberror-perl"
debiangetlatestdebfunc "buster" all "git-man"
cd "$BUILD_DIR"/deps/extracted
debextractfunc () {
    ar x "$BUILD_DIR"/deps/"$1"
    rm -f "$BUILD_DIR"/deps/extracted/control.tar.gz
    rm -f "$BUILD_DIR"/deps/extracted/debian-binary
    tar -xf "$BUILD_DIR"/deps/extracted/data.tar.* -C "$BUILD_DIR"/deps/extracted/
    rm -f "$BUILD_DIR"/deps/extracted/data.tar.*
    if [ -f "$BUILD_DIR"/deps/extracted/usr/share/doc/git/contrib/subtree/COPYING ]; then
        rm "$BUILD_DIR"/deps/extracted/usr/share/doc/git/contrib/subtree/COPYING
    fi
    if [ -f "$BUILD_DIR"/deps/extracted/usr/share/doc/git/contrib/persistent-https/LICENSE ]; then
        rm "$BUILD_DIR"/deps/extracted/usr/share/doc/git/contrib/persistent-https/LICENSE
    fi
    cp -r "$BUILD_DIR"/deps/extracted/* "$BUILD_DIR"/appimagebuild.AppDir/
    rm -rf "$BUILD_DIR"/deps/extracted/*
}

debextractfunc "wget.deb"
debextractfunc "libgnutls30.deb"
debextractfunc "libhogweed4.deb"
debextractfunc "libidn2-0.deb"
debextractfunc "libunistring2.deb"
debextractfunc "libnettle6.deb"
debextractfunc "libpcre3.deb"
debextractfunc "libpsl5.deb"
debextractfunc "libuuid1.deb"
debextractfunc "zlib1g.deb"
debextractfunc "binutils.deb"
debextractfunc "git.deb"
debextractfunc "libcurl3-gnutls.deb"
debextractfunc "liberror-perl.deb"
debextractfunc "git-man.deb"
rm -rf "$BUILD_DIR"/deps

mkdir -p "$BUILD_DIR"/appimagebuild.AppDir/usr/share/appimagebuild
mkdir -p "$BUILD_DIR"/appimagebuild.AppDir/usr/bin
cp ~/github/AppImages/appimagebuild.sh "$BUILD_DIR"/appimagebuild.AppDir/usr/bin/appimagebuild
cp ~/github/AppImages/LICENSE "$BUILD_DIR"/appimagebuild.AppDir/usr/share/appimagebuild/
cp ~/github/AppImages/jq "$BUILD_DIR"/appimagebuild.AppDir/usr/bin/
cp ~/github/AppImages/yaml "$BUILD_DIR"/appimagebuild.AppDir/usr/bin/
cp ~/github/AppImages/spm.png "$BUILD_DIR"/appimagebuild.AppDir/appimagebuild.png
cat >"$BUILD_DIR"/appimagebuild.AppDir/appimagebuild.desktop << EOL
[Desktop Entry]
Type=Application
Encoding=UTF-8
Name=appimagebuild
Comment=Builds AppImages using AppImage Build Scripts
Exec=./usr/bin/appimagebuild
Icon=appimagebuild
Categories=Utility;
Terminal=true

EOL

cat >"$BUILD_DIR"/AppRun.conf << EOL
APPRUN_SET_PATH="TRUE"
APPRUN_SET_LD_LIBRARY_PATH="TRUE"
APPRUN_SET_PYTHONPATH="FALSE"
APPRUN_SET_PYTHONHOME="FALSE"
APPRUN_SET_PYTHONDONTWRITEBYTECODE="FALSE"
APPRUN_SET_XDG_DATA_DIRS="FALSE"
APPRUN_SET_PERLLIB="FALSE"
APPRUN_SET_GSETTINGS_SCHEMA_DIR="FALSE"
APPRUN_SET_QT_PLUGIN_PATH="FALSE"
APPRUN_EXEC="./usr/bin/appimagebuild"

EOL

wget "https://raw.githubusercontent.com/simoniz0r/AppImages/master/resources/AppRun" -O "$BUILD_DIR"/appimagebuild.AppDir/AppRun
chmod a+x "$BUILD_DIR"/appimagebuild.AppDir/AppRun

appimagetool "$BUILD_DIR"/appimagebuild.AppDir "$BUILD_DIR"/appimagebuild-"$VERSION"-x86_64.AppImage || exit 1
rm -rf "$BUILD_DIR"/appimagebuild.AppDir
exit 0
