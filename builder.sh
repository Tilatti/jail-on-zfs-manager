#! /bin/bash

# Initialize the ZFS driver

function init_zfs {

	# Check if the ZFS module is loaded on the kernel.

	kldstat | grep "zfs\.ko" > /dev/null

	# Load the ZFS module if not previously found.

	if [ $? -ne 0 ];
	then
		kldload zfs
	fi
}

# Erase a jail root.

function clean_up {
	ROOT_DIR=$1

	if grep -q "$HOME/.*" <<< "${ROOT_DIR}"
	then
		echo "Clean up the root directory: ${ROOT_DIR}"
	else
		echo "I refuse to clean up the ${ROOT_DIR} directory."
		exit -1
	fi

	# Unmount internal filesystems.

	umount ${ROOT_DIR}/dev/

	# Remove protections on files.

	find ${ROOT_DIR} -exec chflags noschg {} \;
	find ${ROOT_DIR} -exec chmod u+w {} \; > /dev/null

	# Remove content of the root directory.

	rm -rf ${ROOT_DIR}/*
}

# Populate root directoy from sources.

function populate_from_src {
	ROOT_DIR=$1

	cd /usr/src
	make buildworld
	make installworld DESTDIR=${ROOT_DIR}
	make distribution DESTIDR=${ROOT_DIR}
}

# Populate root directory with a binary distribution.

# $1 : root directory to populate
# $2 : ISO with binary distribution
# $3 : binary distributions to install

function populate_from_dist {
	ROOT_DIR=$1
	ISO=$2
	TO_INSTALL=$3

	echo "Populate ${ROOT_DIR} with ${TO_INSTALL} distributions from ${ISO} file."

	#if [ "${TO_INSTALL}" = "all" ]; then
	#	TO_INSTALL=base doc lib32 ports src
	#fi

	# Mount the distribution ISO

	mount -t cd9660 /dev/`mdconfig -f ${ISO}` /mnt

	# Untar on root directory the distribution packages.

	for p in ${TO_INSTALL}
	do
		tar -xf /mnt/usr/freebsd-dist/${p}.txz -C ${ROOT_DIR}
	done

	# Unmount the ISO

	umount /mnt
}

# Populate a root directory.

# $1 : root directory
# $2 : hostname

function populate {
	ROOT_DIR=$1
	HOST_NAME=$2

	# Populate the root directory from sources / from binary distribution.
	if [ ${FROM_SRC} = true ]; then
		populate_from_src ${ROOT_DIR}
	else
		populate_from_dist ${ROOT_DIR} ${ISO} base
	fi
}

# Create a new storage pool

# $1 : output file
# $2 : pool name
# $3 : pool size (M)

function create_storage_pool {
	FILE=$1
	POOL=$2
	POOL_SIZE=$3

	# Initialize ZFS driver.

	init_zfs

	# Create the image file.

	dd if=/dev/zero of=${FILE} bs=1024K count=${POOL_SIZE}

	# Create the pool.

	zpool create -f ${POOL} ${FILE}

	# Activate the printing of snapshots by "zfs list" command.

	zpool set listsnapshots=on ${POOL}
}

# Create a new root image.

# $1 : pool name
# $2 : image name

function create_img {
	POOL=$1
	IMAGE=$2

	# Initialize ZFS driver.

	init_zfs

	# Create the filesystem.

	zfs create ${POOL}/${IMAGE}
}

# Clone an existing image.
# Note: A session can not be directly cloned. A image has to be generated with
# the fix_changes() function.

# $1 : pool name
# $2 : source image name
# $3 : destination image name

function clone_img {
	POOL=$1
	SRC=$2
	DST=$3

	# Initialize ZFS driver.

	init_zfs
	
	# Clone the snapshot assocatied with the image.
	
	zfs clone ${POOL}/${SRC}@snapshot ${POOL}/${DST}
}

# Common final actions for each created image.
# Note: Session rootfs has only to be cloned image. It is the fix_changes() 
# function which call the finalize_img() in order to generate the image.

# $1 : pool name
# $2 : image name

function finalize_img {
	POOL=$1
	IMAGE=$2

	# Create a snapshot of the image, will be used to clone the image.
	
	zfs snapshot ${POOL}/${IMAGE}@snapshot
}

# Remove an existing image.

# $1 : pool name
# $2 : image name to remove
# $3 : force to recursivly remove sub-images

function remove_img {
	POOL=$1
	IMAGE=$2
	FORCE=$3

	# Destroy the ZFS data-set containing the image.

	if [ ${FORCE} = true ];
	then
		zfs destroy -R ${POOL}/${IMAGE}
	else
		zfs destroy ${POOL}/${IMAGE}
	fi

	if [ $? -ne 0 ];
	then
		echo "Warning: the ZFS data-set corresponding to image ${POOL}/${IMAGE} \
		is propably not correctly destroyed." 1>&2
	fi
}

# Default setting.

FROM_SRC=false
CONF_FILE=${HOME}/jail.conf
ISO=/root/FreeBSD-10.2-RELEASE-amd64-disc1.iso

JAIL_NAME=test

# Perform no action by default.

#CLEAN_UP=false
#CREATE=false
#LAUNCH=false
#SHUTDOWN=false
#REMOVE=false

# Parse the arguments.

#while [ "$*" != "" ];
#do
#	case "$1" in
#		'---src')
#			FROM_SRC=true
#			shift
#		;;
#
#		'--root-dir')
#			ROOT_DIR=$2
#			shift 2
#		;;
#
#		'--iso')
#			ISO=$2
#			shift 2
#		;;
#
#		'clean')
#			CLEAN=true
#			shift
#		;;
#
#		'create')
#			CREATE=true
#			shift
#		;;
#
#		'launch')
#			LAUNCH=true
#			shift
#		;;
#
#		'shutdown')
#			SHUTDOWN=true
#			shift
#		;;
#
#		'remove')
#			REMOVE=true
#			shift
#		;;
#
#		* | '--help' | '-h')
#			echo "Bad argument: $1"
#			echo "create_jail.sh usage:"
#			echo "	create_jail.sh [--from-src] [--root-dir <root_dir>] [--iso <iso_file>] clean/create/launch/all"
#			exit -1
#		;;
#	esac
#done
#
## Clean up the root directory.
#
##if [ ${CLEAN} = true ]; then
#	#clean_up ${ROOT_DIR}
##fi
#
## Create a new image.
#
#POOL=zroot
#
##if [ ${CREATE} = true ];
##then
##	#create_img ${POOL} jail_root
##	#clone_img ${POOL} jail_root jail_root_clone1
##	#clone_img ${POOL} jail_root jail_root_clone2
##	#clone_img ${POOL} jail_root_clone2 jail_root_clone3
##fi
#
## Launch the jails.
#
#if [ ${LAUNCH} = true ];
#then
#	for JAIL_NAME in $(ls /${POOL}/)
#	do
#		jail -f /root/jail.conf -c ${JAIL_NAME}
#	done
#fi
#
## Shutdown the jails.
#
#if [ ${SHUTDOWN} = true ];
#then
#	for JAIL_NAME in $(ls /${POOL}/)
#	do
#		jail -f /root/jail.conf -r ${JAIL_NAME}
#	done
#fi
#
## Remove an image.
#
#if [ ${REMOVE} = true ];
#then
#	for JAIL_NAME in $(ls /${POOL}/)
#	do
#		remove_img ${POOL} jail_root
#	done
#fi
