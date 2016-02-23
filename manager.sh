#! /bin/bash

source builder.sh
source session.sh

function print_usage {
	echo "manager.sh usage:"
	echo "	manager.sh create   pool <pool_name> image <image_name> session <session_name>"
	echo "	manager.sh fix 	    pool <pool_name> image <image_name> session <session_name>"
	echo "	manager.sh remove   pool <pool_name>                    session <session_name>"
	echo "	manager.sh launch                                       session <session_name>"
	echo "	manager.sh shutdown                                     session <session_name>"
	echo "	manager.sh help"
}

# Default setting.

JAIL_CONF_FILE=/tmp/jail.conf

# Perform no action by default.

CREATE=false
REMOVE=false
LAUNCH=false
SHUTDOWN=false
FIX=false
HELP=false

# Parse the action to perform (first argument)

case "$1" in
	'create')
		CREATE=true
	;;

	'remove')
		REMOVE=true
	;;

	'launch')
		LAUNCH=true
	;;

	'shutdown')
		SHUTDOWN=true
	;;

	'fix')
		FIX=true
	;;

	'help')
		print_usage
		exit -1
	;;

	*)
		echo "ERROR: Bad specified action !" 1>&2
		print_usage
		exit -1
	;;
esac

shift

# Parse the remaining parameters

POOL=no-pool
IMAGE=no-image
SESSION=no-session

while [ "$*" != "" ];
do
	case "$1" in
		'pool')
			POOL=$2
			shift 2
		;;

		'image')
			IMAGE=$2
			shift 2
		;;

		'session')
			SESSION=$2
			shift 2
		;;

		*)
			echo "ERROR: Bad argument !" 1>&2
			print_usage
			exit -1
		;;
	esac
done

# Create a new session.

if [ ${CREATE} = true ];
then
	# Check if mandatory arguments are specified

	if [ ${POOL} = "no-pool" -o ${IMAGE} = "no-image" \
		-o ${SESSION} = "no-session" ];
	then
		echo "ERROR: A mandatory argument is missing !" 1>&2
		print_usage
		exit -1
	fi
	
	# Check the existence of the image

	# TODO
	#ls /${POOL}/${IMAGE} > /dev/null
	#if [ $? -ne 0 ];
	#then
	#	echo "ERROR: The source image doesn't exist." 1>&2
	#	exit -1
	#fi

	# Add a session from the image.

	add_session ${POOL} ${IMAGE} ${SESSION} 
fi

# Remove an existing session

if [ ${REMOVE} = true ];
then
	# Check if mandatory arguments are specified

	if [ ${POOL} = "no-pool" -o ${SESSION} = "no-session" ];
	then
		echo "ERROR: A mandatory argument is missing !" 1>&2
		print_usage
		exit -1
	fi
	
	# Check the existence of the image

	# TODO
#	ls /${POOL}/${IMAGE} > /dev/null
#	if [ $? -ne 0 ];
#	then
#		echo "ERROR: The source image doesn't exist." 1>&2
#		exit -1
#	fi

	# Add a session from the image.

	remove_session ${POOL} ${SESSION} 
fi


# Fix a session. (create a new image from session modifications)

if [ ${FIX} = true ];
then
	# Check if mandatory arguments are specified

	if [ ${POOL} = "no-pool" -o ${IMAGE} = "no-image" \
		-o ${SESSION} = "no-session" ];
	then
		echo "ERROR: A mandatory argument is missing !" 1>&2
		print_usage
		exit -1
	fi

	# Fix changes of the session.

	fix_changes ${POOL} ${IMAGE} ${SESSION}
fi

# Launch a session

if [ ${LAUNCH} = true ];
then
	# Check if mandatory arguments are specified

	if [ ${SESSION} = "no-session" ];
	then
		echo "ERROR: A mandatory argument is missing !" 1>&2
		print_usage
	fi

	jail -f ${JAIL_CONF_FILE} -c ${SESSION}
fi

# Shutdown a session

if [ ${SHUTDOWN} = true ];
then
	# Check if mandatory arguments are specified

	if [ ${SESSION} = "no-session" ];
	then
		echo "ERROR: A mandatory argument is missing !" 1>&2
		print_usage
	fi

	jail -f ${JAIL_CONF_FILE} -r ${SESSION}
fi
