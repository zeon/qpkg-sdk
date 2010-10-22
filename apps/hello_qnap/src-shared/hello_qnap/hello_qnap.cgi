#!/bin/sh
#================================================================
# Copyright (C) 2010 QNAP Systems, Inc.
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
#  hello_qnap.cgi
#
#	Abstract: 
#   A CGI program for start/stop Hello_QNAP demostrating how to
#   perform tasks requires admin (root) previlledges 
#
#	HISTORY:
#       2010/10/12 -    Andy Chuo
#
#--------------------------------------------

# Retreive command line parameters
paramVar1=`echo $QUERY_STRING | cut -d \& -f 1 | cut -d \= -f 1`
paramVal1=`echo $QUERY_STRING | cut -d \& -f 1 | cut -d \= -f 2`
paramVar2=`echo $QUERY_STRING | cut -d \& -f 2 | cut -d \= -f 1`
paramVal2=`echo $QUERY_STRING | cut -d \& -f 2 | cut -d \= -f 2`
paramVar3=`echo $QUERY_STRING | cut -d \& -f 3 | cut -d \= -f 1`
paramVal3=`echo $QUERY_STRING | cut -d \& -f 3 | cut -d \= -f 2`
paramVar4=`echo $QUERY_STRING | cut -d \& -f 4 | cut -d \= -f 1`
paramVal4=`echo $QUERY_STRING | cut -d \& -f 4 | cut -d \= -f 2`

SYS_MODEL=`/sbin/getcfg system model`;

# Determine Platform type
CPU_MODEL=`uname -m`
KERNEL=`uname -mr | cut -d '-'  -f 1 | cut -d ' '  -f 1`

# Debugging
echo -e "content-type: text/html\n"
echo -e "\n`date`"
echo -e "\nCPU=${CPU_MODEL} / KERNEL=${KERNEL}"
echo -e "\nSCRIPT: hello_qnap.cgi param1[${paramVar1}=${paramVal1}] param2[${paramVar2}=${paramVal2}] param3[${paramVar3}=${paramVal3}] param4[${paramVar4}=${paramVal4}]"

case $paramVar1 in
	# Start/Stop Hello_QNAP
	ftp)
		echo -e "Hello_QNAP: Start/Stop Proftpd ${paramVal1}... "
		/etc/init.d/ftp.sh $paramVal1
		;;
	# Invalid command line parameters
	*)
		echo -e "Usage: $0 {start|stop|restart}"
		exit 1
		;;
esac

exit $?

