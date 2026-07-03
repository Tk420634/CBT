#!/bin/bash
set -e
source dependencies.sh
sudo dpkg --add-architecture i386
sudo apt-get update
sudo apt install libcurl4:i386
echo "Downloading BYOND version $BYOND_MAJOR.$BYOND_MINOR"
curl "http://www.byond.com/download/build/$BYOND_MAJOR/$BYOND_MAJOR.${BYOND_MINOR}_byond.zip" -A "CBT/1.0 Continuous Integration" -o C:/byond.zip
