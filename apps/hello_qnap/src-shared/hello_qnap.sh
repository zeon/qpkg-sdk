#!/bin/sh

RETVAL=0
QPKG_DIR=""
QPKG_NAME="Hello_QNAP"

WEB_SHARE=$(/sbin/getcfg SHARE_DEF defWeb -d Qweb -f /etc/config/def_share.info)

_exit()
{
	/bin/echo -e "Error: $*"
	exit 1
}

find_base() {	
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
		QPKG_DIR="${BASE}/.qpkg/${QPKG_NAME}"
	fi
}

find_base

init_check(){
	if [ `/sbin/getcfg $QPKG_NAME Enable -u -d FALSE -f /etc/config/qpkg.conf` = UNKNOWN ]; then
			/sbin/setcfg $QPKG_NAME Enable TRUE -f /etc/config/qpkg.conf
	elif [ `/sbin/getcfg $QPKG_NAME Enable -u -d FALSE -f /etc/config/qpkg.conf` != TRUE ]; then
			echo "$QPKG_NAME is disabled."
	fi
}

create_links(){
	[ -f /home/httpd/hello_qnap.cgi ] || ln -sf /share/${WEB_SHARE}/hello_qnap/hello_qnap.cgi /home/httpd/
	[ -f /usr/bin/hello_qnap ] || /bin/ln -sf "${QPKG_DIR}/bin/hello_qnap" /usr/bin
	[ -d /share/${WEB_SHARE}/hello_qnap ] || /bin/ln -sf "${QPKG_DIR}/hello_qnap /share/${WEB_SHARE}/hello_qnap"	
}

change_permissions(){
	chmod +x /home/httpd/hello_qnap.cgi
	chmod 777 /share/${WEB_SHARE}/hello_qnap/debug.log
	chmod 666 /share/${WEB_SHARE}/hello_qnap/settings.conf
	chmod 755 ${QPKG_DIR}/bin/hello_qnap
}

. "$QPKG_DIR/hello_qnap.conf"

case "$1" in
	start)
		# Starting Hello_QNAP...
		init_check
		create_links
		change_permissions
		start_hello_qnap		
		RETVAL=$?
	;;
	
	stop)  	
		# Stopping Hello_QNAP...
		stop_hello_qnap				
		RETVAL=$?
	;;

	restart)
		restart_hello_qnap
		RETVAL=$?	
	;;
	
	*)
		echo "Usage: $0 {start|stop|restart}"
		exit 1
esac

exit $RETVAL
