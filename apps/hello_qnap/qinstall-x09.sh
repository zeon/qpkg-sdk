#!/bin/sh
#================================================================
# Copyright (C) 2009 QNAP Systems, Inc.
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#----------------------------------------------------------------
#
# qinstall-x86.sh
#
#	Abstract: 
#		A QPKG installation script for QNAP NAS
#		
#
#	HISTORY:
#
#		2009/05/02	-	Created	- AndyChuo 
# 
#================================================================
#
##### Utils Defines #####
##################################
# add/remove entries according to your needs
##################################
#
CMD_CAT="/bin/cat"
CMD_CHMOD="/bin/chmod"
CMD_CHOWN="/bin/chown"
CMD_CHROOT="/usr/sbin/chroot"
CMD_CMP="/bin/cmp"
CMD_CP="/bin/cp"
CMD_CUT="/bin/cut"
CMD_ECHO="/bin/echo"
CMD_FIND="/usr/bin/find"
CMD_GETCFG="/sbin/getcfg"
CMD_GREP="/bin/grep"
CMD_IFCONFIG="/sbin/ifconfig"
CMD_IPKG="/opt/bin/ipkg"
CMD_KILL="/bin/kill"
CMD_LN="/bin/ln"
CMD_MKDIR="/bin/mkdir"
CMD_MV="/bin/mv"
CMD_READLINK="/usr/bin/readlink"
CMD_RM="/bin/rm"
CMD_SED="/bin/sed"
CMD_SETCFG="/sbin/setcfg"
CMD_SLEEP="/bin/sleep"
CMD_SYNC="/bin/sync"
CMD_TAR="/bin/tar"
CMD_TOUCH="/bin/touch"
CMD_TR="/bin/tr"
CMD_WLOG="/sbin/write_log"
CMD_XARGS="/usr/bin/xargs"
#
##### System Defines #####
##################################
# please do not alter the values below
##################################
#
UPDATE_PROCESS="/tmp/update_process"
UPDATE_PB=0
UPDATE_P1=1
UPDATE_P2=2
UPDATE_PE=3
SYS_HOSTNAME=$(/bin/hostname)
SYS_IP=$($CMD_IFCONFIG eth0 | $CMD_GREP "inet addr" | $CMD_CUT -f 2 -d ':' | $CMD_CUT -f 1 -d ' ')
SYS_CONFIG_DIR="/etc/config" #put the configuration files here
SYS_INIT_DIR="/etc/init.d"
SYS_rcS_DIR="/etc/rcS.d"
SYS_rcK_DIR="/etc/rcK.d"
SYS_QPKG_CONFIG_FILE="/etc/config/qpkg.conf" #qpkg infomation file
SYS_QPKG_CONF_FIELD_QPKGFILE="QPKG_File"
SYS_QPKG_CONF_FIELD_NAME="Name"
SYS_QPKG_CONF_FIELD_VERSION="Version"
SYS_QPKG_CONF_FIELD_ENABLE="Enable"
SYS_QPKG_CONF_FIELD_DATE="Date"
SYS_QPKG_CONF_FIELD_SHELL="Shell"
SYS_QPKG_CONF_FIELD_INSTALL_PATH="Install_Path"
SYS_QPKG_CONF_FIELD_CONFIG_PATH="Config_Path"
SYS_QPKG_CONF_FIELD_WEBUI="WebUI"
SYS_QPKG_CONF_FIELD_WEBPORT="Web_Port"
SYS_QPKG_CONF_FIELD_SERVICEPORT="Service_Port"
SYS_QPKG_CONF_FIELD_SERVICE_PIDFILE="Pid_File"
SYS_QPKG_CONF_FIELD_AUTHOR="Author"
#
##### QPKG Info #####
##################################
# please enter the details below
##################################
#
. qpkg.cfg
#
##### System Functions (do not alter any unless you know what your doing) ######
##################################
# custum exit
##################################
#
_exit(){
	local ret=0
	
	case $1 in
		0)#normal exit
			ret=0
			if [ "x$QPKG_INSTALL_MSG" != "x" ]; then
				$CMD_WLOG "${QPKG_INSTALL_MSG}" 4
			else
				$CMD_WLOG "${QPKG_NAME} ${QPKG_VER} installation succeeded." 4
			fi
			$CMD_ECHO "$UPDATE_PE" > ${UPDATE_PROCESS}
		;;
		*)
			ret=1
			if [ "x$QPKG_INSTALL_MSG" != "x" ];then
				$CMD_WLOG "${QPKG_INSTALL_MSG}" 1
			else
				$CMD_WLOG "${QPKG_NAME} ${QPKG_VER} installation failed" 1
			fi
			$CMD_ECHO -1 > ${UPDATE_PROCESS}
		;;
	esac	
	exit $ret
}
#
##################################
# Determine BASE installation location and assigned to $QPKG_DIR
##################################
#
find_base(){	
	BASE=""
	DEV_DIR="HDA HDB HDC HDD HDE HDF HDG HDH MD0 MD1 MD2 MD3"
	publicdir=`/sbin/getcfg Public path -f /etc/config/smb.conf`
	if [ ! -z $publicdir ] && [ -d $publicdir ];then
		BASE=`echo $publicdir |awk -F/Public '{ print $1 }'`
	else
		for datadirtest in $DEV_DIR; do
			[ -d /share/${datadirtest}_DATA/Public ] && BASE=/share/${datadirtest}_DATA
		done
	fi
	if [ -z $BASE ]; then
		echo "The base directory cannot be found."
		_exit 1
	else
		QPKG_INSTALL_PATH="${BASE}/.qpkg"
		QPKG_DIR="${QPKG_INSTALL_PATH}/${QPKG_NAME}"
	fi
}
#
##################################
# Link service start/stop script
##################################
#
link_start_stop_script(){
	if [ "x${QPKG_SERVICE_PROGRAM}" != "x" ]; then
		$CMD_ECHO "Link service start/stop script: ${QPKG_SERVICE_PROGRAM}"
		$CMD_LN -sf "${QPKG_DIR}/${QPKG_SERVICE_PROGRAM}" "${SYS_INIT_DIR}/${QPKG_SERVICE_PROGRAM}"
		$CMD_LN -sf "${SYS_INIT_DIR}/${QPKG_SERVICE_PROGRAM}" "${SYS_rcS_DIR}/QS${QPKG_RC_NUM}${QPKG_NAME}"
		$CMD_LN -sf "${SYS_INIT_DIR}/${QPKG_SERVICE_PROGRAM}" "${SYS_rcK_DIR}/QK${QPKG_RC_NUM}${QPKG_NAME}"
		$CMD_CHMOD 755 "${QPKG_DIR}/${QPKG_SERVICE_PROGRAM}"
	fi

	# Only applied on TS-109/209/409 for chrooted env
	if [ -d ${QPKG_ROOTFS} ]; then
		if [ "x${QPKG_SERVICE_PROGRAM_CHROOT}" != "x" ]; then
			$CMD_MV ${QPKG_DIR}/${QPKG_SERVICE_PROGRAM_CHROOT} ${QPKG_ROOTFS}/etc/init.d
			$CMD_CHMOD 755 ${QPKG_ROOTFS}/etc/init.d/${QPKG_SERVICE_PROGRAM_CHROOT}
		fi
	fi
}
#
##################################
# Set QPKG information
##################################
#
register_qpkg(){
	$CMD_ECHO "Set QPKG information to $SYS_QPKG_CONFIG_FILE"
	[ -f ${SYS_QPKG_CONFIG_FILE} ] || $CMD_TOUCH ${SYS_QPKG_CONFIG_FILE}
	$CMD_SETCFG ${QPKG_NAME} ${SYS_QPKG_CONF_FIELD_NAME} "${QPKG_NAME}" -f ${SYS_QPKG_CONFIG_FILE}
	$CMD_SETCFG ${QPKG_NAME} ${SYS_QPKG_CONF_FIELD_VERSION} "${QPKG_VER}" -f ${SYS_QPKG_CONFIG_FILE}
		
	#default value to activate(or not) your QPKG if it was a service/daemon
	$CMD_SETCFG ${QPKG_NAME} ${SYS_QPKG_CONF_FIELD_ENABLE} "UNKNOWN" -f ${SYS_QPKG_CONFIG_FILE}

	#set the qpkg file name
	[ "x${SYS_QPKG_CONF_FIELD_QPKGFILE}" = "x" ] && $CMD_ECHO "Warning: ${SYS_QPKG_CONF_FIELD_QPKGFILE} is not specified!!"
	[ "x${SYS_QPKG_CONF_FIELD_QPKGFILE}" = "x" ] || $CMD_SETCFG ${QPKG_NAME} ${SYS_QPKG_CONF_FIELD_QPKGFILE} "${QPKG_QPKG_FILE}" -f ${SYS_QPKG_CONFIG_FILE}
	
	#set the date of installation
	$CMD_SETCFG ${QPKG_NAME} ${SYS_QPKG_CONF_FIELD_DATE} $(date +%F) -f ${SYS_QPKG_CONFIG_FILE}
	
	#set the path of start/stop shell script
	[ "x${QPKG_SERVICE_PROGRAM}" = "x" ] || $CMD_SETCFG ${QPKG_NAME} ${SYS_QPKG_CONF_FIELD_SHELL} "${QPKG_DIR}/${QPKG_SERVICE_PROGRAM}" -f ${SYS_QPKG_CONFIG_FILE}
	
	#set path where the QPKG installed, should be a directory
	$CMD_SETCFG ${QPKG_NAME} ${SYS_QPKG_CONF_FIELD_INSTALL_PATH} "${QPKG_DIR}" -f ${SYS_QPKG_CONFIG_FILE}

	#set path where the QPKG configure directory/file is
	[ "x${QPKG_CONFIG_PATH}" = "x" ] || $CMD_SETCFG ${QPKG_NAME} ${SYS_QPKG_CONF_FIELD_CONFIG_PATH} "${QPKG_CONFIG_PATH}" -f ${SYS_QPKG_CONFIG_FILE}
	
	#set the port number if your QPKG was a service/daemon and needed a port to run.
	[ "x${QPKG_SERVICE_PORT}" = "x" ] || $CMD_SETCFG ${QPKG_NAME} ${SYS_QPKG_CONF_FIELD_SERVICEPORT} "${QPKG_SERVICE_PORT}" -f ${SYS_QPKG_CONFIG_FILE}

	#set the port number if your QPKG was a service/daemon and needed a port to run.
	[ "x${QPKG_WEB_PORT}" = "x" ] || $CMD_SETCFG ${QPKG_NAME} ${SYS_QPKG_CONF_FIELD_WEBPORT} "${QPKG_WEB_PORT}" -f ${SYS_QPKG_CONFIG_FILE}

	#set the URL of your QPKG Web UI if existed.
	[ "x${QPKG_WEBUI}" = "x" ] || $CMD_SETCFG ${QPKG_NAME} ${SYS_QPKG_CONF_FIELD_WEBUI} "${QPKG_WEBUI}" -f ${SYS_QPKG_CONFIG_FILE}

	#set the pid file path if your QPKG was a service/daemon and automatically created a pidfile while running.
	[ "x${QPKG_SERVICE_PIDFILE}" = "x" ] || $CMD_SETCFG ${QPKG_NAME} ${SYS_QPKG_CONF_FIELD_SERVICE_PIDFILE} "${QPKG_SERVICE_PIDFILE}" -f ${SYS_QPKG_CONFIG_FILE}

	#Sign up
	[ "x${QPKG_AUTHOR}" = "x" ] && $CMD_ECHO "Warning: ${SYS_QPKG_CONF_FIELD_AUTHOR} is not specified!!"
	[ "x${QPKG_AUTHOR}" = "x" ] || $CMD_SETCFG ${QPKG_NAME} ${SYS_QPKG_CONF_FIELD_AUTHOR} "${QPKG_AUTHOR}" -f ${SYS_QPKG_CONFIG_FILE}		
}
#
##################################
# Check existing installation
##################################
#
check_existing_install(){
	CURRENT_QPKG_VER="$($CMD_GETCFG ${QPKG_NAME} Version -f $SYS_QPKG_CONFIG_FILE)"
	QPKG_INSTALL_MSG="${QPKG_NAME} ${CURRENT_QPKG_VER} is already installed. Setup will now perform package upgrading."
	$CMD_ECHO "$QPKG_INSTALL_MSG"			
}
#
##################################
# Custom variables
##################################
#
#
##################################
# Custom functions
##################################
#
# check if given QPKG package exists and is enabled
#
# Usage: is_qpkg_enabled <QPKG>
#
# returns 1 if QPKG doesn't exists, otherwise it returns 0.
#
is_qpkg_enabled(){
	ENABLED=$($CMD_GETCFG "$1" "${SYS_QPKG_CONF_FIELD_ENABLE}" -d "UNKNOWN" -f "${SYS_QPKG_CONFIG_FILE}")
	[ "$ENABLED" = "TRUE" ] || return 1
}
#
##################################
# Pre-remove routine
##################################
#
PRE_REMOVE="{

	# add your own routines below

}"
#
##################################
# Main remove routine
##################################
#
MAIN_REMOVE="{
	# remove QPKG directory, init-scripts, and icons
	$CMD_RM -rf "$QPKG_DIR"
	$CMD_RM -f "${SYS_INIT_DIR}/${QPKG_SERVICE_PROGRAM}"
	$CMD_FIND $SYS_rcS_DIR -type l -name 'QS*${QPKG_NAME}' | $CMD_XARGS $CMD_RM -f 
	$CMD_FIND $SYS_rcK_DIR -type l -name 'QK*${QPKG_NAME}' | $CMD_XARGS $CMD_RM -f
	$CMD_RM -f "/home/httpd/RSS/images/${QPKG_NAME}.gif"
	$CMD_RM -f "/home/httpd/RSS/images/${QPKG_NAME}_80.gif"
	$CMD_RM -f "/home/httpd/RSS/images/${QPKG_NAME}_gray.gif"

	# add your own routines below

}"
#
##################################
# Post-remove routine
##################################
#
POST_REMOVE="{

	# add your own routines below

}"
#
##################################
# Pre-install routine
##################################
#
pre_install(){
	# stop the service before we start the installation #(Do not remove, required routine)
	[ -x $SYS_INIT_DIR/${QPKG_SERVICE_PROGRAM} ] && $SYS_INIT_DIR/${QPKG_SERVICE_PROGRAM} stop
	$CMD_SLEEP 5
	$CMD_SYNC

	# look for the base dir to install and assign the value to $QPKG_DIR
	find_base #(Do not remove, required routine)

	# add your own routines below

}
#
##################################
# Post-install routine
##################################
#
post_install(){
	# create rcS/rcK start/stop scripts 
	link_start_stop_script	#(Do not remove, required routine)
	register_qpkg 		#(Do not remove, required routine)
	
	# add your own routines below
}
#
##################################
# Pre-update routine
##################################
#
pre_update(){
	# add your own routines below
	echo ""
}
#
##################################
# Update routines
##################################
#
update_routines(){
	# add your own routines below
	$CMD_TAR xzf "${QPKG_SOURCE_DIR}/${QPKG_SOURCE_FILE}"  --exclude=hello_qnap.conf -C ${QPKG_DIR}
}
#
##################################
# Post-update routine
##################################
#
post_update(){
	# add your own routines below
	echo ""
}
#
##################################
# Install routines
##################################
install_routines(){
	# add your own routines below
	echo ""
}
#
##################################
# Create uninstall script
##################################
#
create_uninstall_script(){
	QPKG_UNINSTALL_SCRIPT="${QPKG_DIR}/.uninstall.sh"

	# save stdout to fd 5
	exec 5>&1

	# redirect all output to uninstall script
	exec > "$QPKG_UNINSTALL_SCRIPT"

	$CMD_CAT <<-EOF
	#!/bin/sh

	$PRE_REMOVE
	$MAIN_REMOVE
	$POST_REMOVE

	EOF

	# restore stdout and close fd 5
	exec 1>&5 5>&-

	$CMD_CHMOD 755 "$QPKG_UNINSTALL_SCRIPT"
}
#
##################################
# Check requirements routines
#
# If all requirements are fulfilled
# then return 0, otherwise return 1
##################################
check_requirements_ok(){
	# assign any error message to QPKG_REQUIRE_MSG before function returns
	QPKG_REQUIRE_MSG=""
	if [ "x${QPKG_REQUIRE}" != "x" ]; then
		# check that required QPKG packages exist and are enabled
		OLDIFS="$IFS"; IFS=,
		set $QPKG_REQUIRE
		IFS="$OLDIFS"
		for qpkg
		do
			is_qpkg_enabled "$qpkg" || QPKG_REQUIRE_MSG="${QPKG_REQUIRE_MSG}'${qpkg}' "
		done
		if [ "$QPKG_REQUIRE_MSG" != "" ]; then
			QPKG_REQUIRE_MSG="The following QPKG must be installed and enabled first: ${QPKG_REQUIRE_MSG}"
			return 1
		fi
	fi

	# add your own routines below

	# return success (do not remove)
	return 0
}
#
##################################
# Main installation
##################################
#
install(){
	# check requirements routines (do not remove, required routine)
	check_requirements_ok || return 3

	# pre install routines (do not remove, required routine)
	pre_install
	
	if [ -f "${QPKG_SOURCE_DIR}/${QPKG_SOURCE_FILE}" ]; then
		
		# check for existing install
		if [ -d ${QPKG_DIR} ]; then
			check_existing_install
			UPDATE_FLAG=1
			
			# pre update routines (do not remove, required routine)
			pre_update
		else
			# create main QNAP installation folder
			$CMD_MKDIR -p ${QPKG_DIR}
		fi

		# install/update QPKG files 		
		if [ ${UPDATE_FLAG} -eq 1 ]; then
			# update routines (do not remove, required routine)
			update_routines 
			
			# post update routines (do not remove, required routine)
			post_update
		else
			# decompress the QNAP file (do not remove, required routine)
			$CMD_TAR xzf "${QPKG_SOURCE_DIR}/${QPKG_SOURCE_FILE}" -C ${QPKG_DIR}
			if [ $? = 0 ]; then
				# installation routines
				install_routines
			else
				return 2
			fi
		fi
		
		# install progress indicator (do not remove, required routine)
		$CMD_ECHO "$UPDATE_P2" > ${UPDATE_PROCESS}
		
		# post install routines (do not remove, required routine)
		post_install

		# create uninstall script (do not remove, required routine)
		create_uninstall_script
		
		$CMD_SYNC
		return 0
	else
		return 1		
	fi
}
#
##################################
# Main
##################################
#
# install progress indicator
$CMD_ECHO "$UPDATE_PB" > ${UPDATE_PROCESS}

install
status=$?
if [ "$status" = "0" ]; then
	QPKG_INSTALL_MSG="${QPKG_NAME} ${QPKG_VER} has been installed in $QPKG_DIR."
	$CMD_ECHO "$QPKG_INSTALL_MSG"
	_exit 0
elif [ "$status" = "1" ]; then
	QPKG_INSTALL_MSG="${QPKG_NAME} ${QPKG_VER} installation failed. ${QPKG_SOURCE_DIR}/${QPKG_SOURCE_FILE} file not found."
	$CMD_ECHO "$QPKG_INSTALL_MSG"
	_exit 1
elif [ "$status" = "2" ]; then
	${CMD_RM} -rf ${QPKG_INSTALL_PATH}
	QPKG_INSTALL_MSG="${QPKG_NAME} ${QPKG_VER} installation failed. ${QPKG_SOURCE_DIR}/${QPKG_SOURCE_FILE} file error."
	$CMD_ECHO "$QPKG_INSTALL_MSG"
	_exit 1
elif [ "$status" = "3" ]; then
	QPKG_INSTALL_MSG="${QPKG_NAME} ${QPKG_VER} installation failed. Failed requirement: ${QPKG_REQUIRE_MSG}"
	$CMD_ECHO "$QPKG_INSTALL_MSG"
	_exit 1
else
	# never reach here
	echo ""
fi