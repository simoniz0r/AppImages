#!/bin/bash
# Title: appinagebuild
# Description: Builds AppImages using AppImage Build Scripts
# Dependencies: coreutils, wget
# Dependencies that may be used during builds: binutils, git, jq, tar, yaml
# Author: simonizor
# Website: http://www.simonizor.gq
# License: GPL v2.0 only

X="0.0.3"
# Set appimagebuild version
CONFDIR="$HOME/.config/appimagebuild"

if [ ! -d "$CONFDIR" ]; then
    mkdir -p "$CONFDIR"/cache
fi

if [ -f ~/.config/appimagebuild/appimagebuild.conf ]; then
    . ~/.config/appimagebuild/appimagebuild.conf
fi

if ! type wget >/dev/null 2>&1; then
    MISSING_DEPS="TRUE"
    echo "$(tput setaf 1)wget is not installed!$(tput sgr0)"
fi
if [ "$MISSING_DEPS" = "TRUE" ]; then
    echo "$(tput setaf 1)Missing one or more packages required to run; exiting...$(tput sgr0)"
    exit 1
fi

aibsdlfunc () { # Downloads AppImage Build Script (aibs) from the aibs branch of spm's github repo
    wget --no-verbose "https://raw.githubusercontent.com/simoniz0r/AppImages/master/"$AIBSIMG".aibs" -O "$CONFDIR"/cache/"$AIBSIMG".aibs || { echo "$(tput setaf 1)$AIBSIMG not found!$(tput sgr0)"; rm -rf "$CONFDIR"/cache/*; exit 1; }
}

aibsbuildfunc () { # Builds specified AppImage using instructions from the aibs
    echo "Sourcing in aibs for $(tput setaf 4)$AIBSIMG$(tput sgr0)..."
    source "$CONFDIR"/cache/"$AIBSIMG".aibs
    echo "Checking for dependencies needed for building AppImage for $(tput setaf 4)$AIBSIMG$(tput sgr0)..."
    aibsdepcheckfunc
    echo "Creating temporary directories for building $(tput setaf 4)$AIBSIMG$(tput sgr0)..."
    mkdir "$CONFDIR"/cache/"$AIBSIMG_NAME".AppDir
    AIBSIMG_BUILD_DIR=""$CONFDIR"/cache/"$AIBSIMG_NAME".AppDir"
    mkdir "$CONFDIR"/cache/"$AIBSIMG"_source
    AIBSIMG_SOURCE_DIR=""$CONFDIR"/cache/"$AIBSIMG"_source"
    mkdir "$CONFDIR"/cache/"$AIBSIMG"_deps
    AIBSIMG_DEPS_DIR=""$CONFDIR"/cache/"$AIBSIMG"_deps"
    mkdir "$CONFDIR"/cache/"$AIBSIMG"_temp
    AIBSIMG_TEMP_DIR=""$CONFDIR"/cache/"$AIBSIMG"_temp"
    echo "Downloading AppRun file for running $(tput setaf 4)$AIBSIMG$(tput sgr0) AppImage..."
    wget --no-verbose "https://raw.githubusercontent.com/simoniz0r/AppImages/master/resources/AppRun" -O "$AIBSIMG_BUILD_DIR"/AppRun
    chmod a+x "$AIBSIMG_BUILD_DIR"/AppRun
    if [ "$AIBSIMG_USE_WRAPPER" = "TRUE" ]; then
        echo "Downloading wrapper for $(tput setaf 4)$AIBSIMG$(tput sgr0)..."
        wget --no-verbose "https://raw.githubusercontent.com/simoniz0r/AppImages/master/resources/desktopintegration" -O "$AIBSIMG_BUILD_DIR"/"$AIBSIMG_NAME".wrapper
        chmod a+x "$AIBSIMG_BUILD_DIR"/"$AIBSIMG_NAME".wrapper
    fi
    echo "Downloading source files for $(tput setaf 4)$AIBSIMG$(tput sgr0)..."
    aibsversionfunc  || { echo "$(tput setaf 1)Failed!$(tput sgr0)"; rm -rf "$CONFDIR"/cache/*; exit 1; }
    aibsdlsourcefunc || { echo "$(tput setaf 1)Failed!$(tput sgr0)"; rm -rf "$CONFDIR"/cache/*; exit 1; }
    echo "Downloading dependencies for $(tput setaf 4)$AIBSIMG$(tput sgr0)..."
    aibsdldepsfunc || { echo "$(tput setaf 1)Failed!$(tput sgr0)"; rm -rf "$CONFDIR"/cache/*; exit 1; }
    echo "Preparing source files and dependencies for AppImage build and moving them to $(tput setaf 4)$AIBSIMG$(tput sgr0).AppDir ..."
    aibsbuildfunc || { echo "$(tput setaf 1)Failed!$(tput sgr0)"; rm -rf "$CONFDIR"/cache/*; exit 1; }
    if [ "$AIBSIMG_USE_SPECIAL_INSTRUCTIONS" = "TRUE" ]; then
        echo "Executing special build function for $(tput setaf 4)$AIBSIMG$(tput sgr0)..."
        aibsspecialfunc || { echo "$(tput setaf 1)Failed!$(tput sgr0)"; rm -rf "$CONFDIR"/cache/*; exit 1; }
    fi
    echo "Downloading appimagetool to build the AppImage for $(tput setaf 4)$AIBSIMG$(tput sgr0)..."
    wget --no-verbose "https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-x86_64.AppImage" -O "$CONFDIR"/cache/appimagetool
    chmod a+x "$CONFDIR"/cache/appimagetool
    echo "Using appimagetool to build AppImage for $(tput setaf 4)$AIBSIMG$(tput sgr0) using files in $(tput setaf 4)$AIBSIMG$(tput sgr0).AppDir..."
    ARCH="x86_64" "$CONFDIR"/cache/appimagetool -n "$AIBSIMG_BUILD_DIR" "$CONFDIR"/cache/"$AIBSIMG_NAME"-"$AIBSIMG_VERSION".AppImage || { echo "$(tput setaf 1)appimagetool failed to build AppImage for $AIBSIMG; exiting...$(tput sgr0)"; rm -rf "$CONFDIR"/cache/*; exit 1; }
    echo "AppImage for $(tput setaf 4)$AIBSIMG$(tput sgr0) has been built!"
}

aibshelpfunc () {
printf '%s\n' "appimagebuild $X
Usage appimagebuild [argument] [input]

appimagebuild is a tool for easily creating AppImages using AppImage Build Scripts (aibs).
The aibs for building the selected AppImage will either be downloaded from appimagebuild's github
repo or it can be sourced in locally.  If no output path is specified, $HOME/downloads will be used
by default.

Arguments:
    -n    - Specify the name of the AppImage to build (required)
    -l    - Use a local script to build an AppImage (optional; if used, must be followed by the full path to the aibs)
    -o    - Specify the output directory of the AppImage (optional; if used, must be followed by the full output path)

Examples:
    appimagebuild -n discord-stable
    appimagebuild -n discord-stable -o $HOME/AppImages
    appimagebuild -n discord-stable -l $HOME/discord-stable.aibs
    appimagebuild -n discord-stable -l $HOME/discord-stable.aibs -o $HOME/AppImages"
}

if [ -z "$3" ]; then
    case $1 in
        -n)
            shift
            AIBSIMG="$1"
            echo "Downloading aibs for $(tput setaf 4)$AIBSIMG$(tput sgr0)..."
            aibsdlfunc || { echo "aibs download failed; exiting..."; rm -rf "$CONFDIR"/cache/*; exit 1; }
            ;;
        -h*|--h*)
            rm -rf "$CONFDIR"/cache/*
            aibshelpfunc
            exit 0
            ;;
        *)
            echo "$(tput setaf 1)Package input required; exiting...$(tput sgr0)"
            rm -rf "$CONFDIR"/cache/*
            echo
            aibshelpfunc
            exit 1
            ;;
    esac
else
    for arg in "$@"; do
        case $arg in
            -n)
                shift
                AIBSIMG="$1"
                shift
                ;;
            -o)
                shift
                OUTPUT_DIR="$1"
                shift
                ;;
            -l)
                shift
                echo "Sourcing in aibs from $(tput setaf 4)$1$(tput sgr0)..."
                cp "$1" "$CONFDIR"/cache/"$AIBSIMG".aibs || { echo "Failed to source aibs; exiting..."; rm -rf "$CONFDIR"/cache/*; exit 1; }
                shift
                ;;
        esac
    done
fi
if [ -z "$AIBSIMG" ]; then
    echo "$(tput setaf 1)Package input required; exiting...$(tput sgr0)"
    rm -rf "$CONFDIR"/cache/*
    echo
    aibshelpfunc
    exit 1
fi
aibsbuildfunc || { echo "AppImage build failed; exiting..."; rm -rf "$CONFDIR"/cache/*; exit 1; }
if [ -f "$CONFDIR/cache/$AIBSIMG_NAME-$AIBSIMG_VERSION.AppImage" ]; then
    echo "Moving $(tput setaf 4)$AIBSIMG$(tput sgr0) AppImage to $OUTPUT_DIR"
    mv "$CONFDIR"/cache/"$AIBSIMG_NAME"-"$AIBSIMG_VERSION".AppImage "$OUTPUT_DIR"/ || { echo "$(tput setaf 1)Failed!$(tput sgr0)"; rm -rf "$CONFDIR"/cache/*; exit 1; }
    echo "$(tput setaf 4)$AIBSIMG$(tput sgr0) AppImage moved to $OUTPUT_DIR/$(tput setaf 4)$AIBSIMG$(tput sgr0)-"$AIBSIMG_VERSION".AppImage!"
else
    echo "$(tput setaf 1)$AIBSIMG-"$AIBSIMG_VERSION".AppImage not found!  Build failed!$(tput sgr0)"
    rm -rf "$CONFDIR"/cache/*
    exit 1
fi
rm -rf "$CONFDIR"/cache/*
exit 0
