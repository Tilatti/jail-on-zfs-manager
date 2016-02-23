#! /bin/bash

source builder.sh

# A session is an active jail associated with an image.
# A session can be built from an image with the add_session() function.
# After modification done on the session an new image can be generated with
# the fix_changes() function. Modifications can be also discared with
# erase_session() function.

CONF_FILE=/tmp/jail.conf

# Add a session corresponding to an image.

# $1 : pool name
# $2 : image name to start with
# $3 : session name to create

NET_INTERFACE=re0
IP_ADDR="192.168.1.1/24"

function add_session {
	POOL=$1
	IMAGE=$2
	SESSION=$3
	
	# First create the root filesystem by cloning the image.

	clone_img ${POOL} ${IMAGE} ${SESSION}-session
	ROOT_DIR=/${POOL}/${SESSION}-session

	# Add a configuration entry on the jail configuration file.

	cat >> ${CONF_FILE} <<- EOF
		${SESSION} {
			path=${ROOT_DIR};
			mount.devfs;

			exec.start = "/bin/sh /etc/rc";
			exec.stop = "/bin/sh /etc/rc.shutdown";

			host.hostname = ${SESSION};
			ip4.addr = ${IP_ADDR};
			interface = ${NET_INTERFACE};
			allow.raw_sockets;
		}
	EOF
}

# Remove an active session.
# This 

# $1 : pool name
# $2 : session name to erase

function remove_session {
	POOL=$1
	SESSION=$2

	# TODO : sed to remove the conf entry
	# TODO : zfs destroy to remove the cloned image
}

# Fix changes performed during a session, generate a new image.

# $1 : pool name
# $2 : image name to fix on
# $3 : session name

function fix_changes {
	POOL=$1
	IMAGE=$2
	SESSION=$3

	# Rename the session rootfs to the new image name

	zfs rename ${POOL}/${SESSION}-session ${POOL}/${IMAGE}

	# Remove the session
	
	remove_session ${POOL} ${SESSION}

	# Finalize the image in order to be able to create new image and
	# session from it
	
	finalize_img ${POOL} ${IMAGE}
}
