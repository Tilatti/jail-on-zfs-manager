#! /bin/bash

echo "Building freebsd image ..."

source builder.sh

POOL=$1
ISO=../FreeBSD-10.2-RELEASE-amd64-disc1.iso

# Clone the freebsd-minimal image.

clone_img ${POOL} freebsd-minimal freebsd
ROOT_DIR=/${POOL}/freebsd/

# Populate the freebsd image with the complete binary distribution.

populate_from_dist ${ROOT_DIR} ${ISO} "doc lib32 ports src"

# Finalize the image

finalize_img ${POOL} freebsd
