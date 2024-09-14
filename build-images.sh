#!/bin/bash

set -u
set -e

echo "While you're waiting, please open your /etc/hosts with Sublime and add:"
echo "127.0.0.1 c8.9.0.local c8.8.0.local c8.5.8.local c7.19.0.local"
echo "If you clean up a VM, don't forget to clean up the confluence-home directory"
read -p "Press ENTER"

if [[ "$(uname -m)" == "arm64" ]] ; then
    # We're on Apple M1
    echo "Building images for Apple M1 (arm64)"
    ./build-image.sh confluence 9.0.1  --apple
    ./build-image.sh confluence 8.9.0  --apple
    ./build-image.sh confluence 8.5.8  --apple
    ./build-image.sh confluence 7.19.0 --apple
    ./build-image.sh jira 9.4.0 --apple
    ./build-image.sh jira 9.17.0 --apple
    ./build-image.sh jira 10.0.0 --apple
else
    echo "Building images for Intel processors ($(uname -m))"
    ./build-image.sh confluence 9.0.1
    ./build-image.sh confluence 8.9.0
    ./build-image.sh confluence 8.5.8
    ./build-image.sh confluence 7.19.0
    ./build-image.sh jira 9.4.0
    ./build-image.sh jira 9.17.0
    ./build-image.sh jira 10.0.0
fi
