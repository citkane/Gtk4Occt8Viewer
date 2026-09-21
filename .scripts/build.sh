#!/usr/bin/bash

THIS_DIR=$(dirname $BASH_SOURCE)
export CCACHE_SLOPPINESS=pch_defines,time_macros

source $THIS_DIR/build/viewer.sh
source $THIS_DIR/build/occt.sh
source $THIS_DIR/build/peel.sh
source $THIS_DIR/build/example.sh
