#! /bin/bash

echo "Building freebsd-minimal jail ..."

source builder.sh

POOL=$1
ISO=../FreeBSD-10.2-RELEASE-amd64-disc1.iso

# Create the freebsd minimal image.

create_img ${POOL} freebsd-minimal
ROOTDIR=/${POOL}/freebsd-minimal/

# Populate the new image.

populate_from_dist ${ROOT_DIR} ${ISO} base

# Create a setting script.

cat > ${ROOT_DIR}/sys_init.sh <<- EOF
	#! /bin/sh
	echo "hostname=${HOST_NAME}" >> /etc/rc.conf
	echo 'keymap="fr.iso.acc.kbd"' >> /etc/rc.conf
	echo "user::::::User:/home/user/:/bin/sh:user_passwd" | adduser -f -
EOF
chmod +x ${ROOT_DIR}/sys_init.sh

# Launch the setting script inside the jail.

jail -c path=${ROOT_DIR} mount.devfs command=/sys_init.sh

# Finalize the image

finalize_img ${POOL} freebsd-minimal
