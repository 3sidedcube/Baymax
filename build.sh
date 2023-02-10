#!/usr/bin/env bash

#
# Script: build.sh
# Usage: ./build.sh
#
# Uses xcodebuild to build the swift package.
#
xcodebuild \
    -scheme Baymax \
    -destination generic/platform=iOS \
    -quiet \
    build

