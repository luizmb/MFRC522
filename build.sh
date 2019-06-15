#!/bin/sh

project=RPi
user=pi
host=raspberrypi
destination="~/Documents/code/${project}"

# Create Raspberry Pi's destination directory
echo "**** ****"
echo "Creating folder ${destination} on ${host}"
echo "**** ****"
ssh ${user}@${host} mkdir -p $destination

# Send source code to Raspberry Pi
echo "**** ****"
echo "Sending source code to ${host}"
echo "**** ****"
rsync \
    -azP \
    --exclude=".build*" \
    --exclude="Packages/*" \
    --exclude=".swiftpm*" \
    --exclude="*.xcodeproj*" \
    --exclude="*.DS_Store*" \
    --exclude="build.sh" \
    . ${user}@${host}:${destination}

# Build on Pi
echo "**** ****"
echo "Building folder ${destination} on ${host}"
echo "**** ****"
ssh ${user}@${host} "cd ${destination}; swift build"

# Copy binaries from Raspberry Pi back to the Mac
echo "**** ****"
echo "Copying binaries from ${destination}/.build on ${host} to local computer"
echo "**** ****"
rsync \
    -azP \
    ${user}@${host}:${destination}/.build .
