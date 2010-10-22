#!/bin/sh

# global defs
QPKG_PACKAGE_SCRIPT=../../scripts/qpkg_build_QNAP.sh
QPKG_BUILTIN_SCRIPT=../../scripts/built-in.sh 
QPKG_HW_MODEL="$1"
 
QPKG_INSTALL_SCRIPT=qinstall.sh
QPKG_INSTALL_SCRIPT_ARM_X09=qinstall-x09.sh
QPKG_INSTALL_SCRIPT_ARM_X19=qinstall-x19.sh
QPKG_INSTALL_SCRIPT_X86_X39=qinstall-x86.sh
QPKG_INSTALL_SCRIPT_ALL=qinstall-all.sh

NAS_MODELS=""
ALL_ARM_BASED_X09_MODELS="TS-109 TS-209 TS-409 TS-409U"
ALL_ARM_BASED_X19_MODELS="TS-119 TS-219"
ALL_X86_BASED_X39_MODELS="TS-509 TS-439 TS-639 TS-809 TS-809U TS-239 SS-439 SS-839"
ALL_MODELS="${ALL_ARM_BASED_X09_MODELS} ${ALL_ARM_BASED_X19_MODELS} ${ALL_X86_BASED_X39_MODELS}"

SRC_DIR_NAME=""
SRC_DIR_NAME_X09=src-x09
SRC_DIR_NAME_X19=src-x19
SRC_DIR_NAME_X39=src-x86
SRC_DIR_NAME_ALL=src-all
SRC_DIR_NAME_SHARED=src-shared

QPKG_CFG_FILE=qpkg.cfg
QPKG_CFG_FILE_ARMX09=qpkg_arm-x09.cfg
QPKG_CFG_FILE_ARMX19=qpkg_arm-x19.cfg
QPKG_CFG_FILE_X86=qpkg_x86.cfg
QPKG_CFG_FILE_ALL=qpkg_all.cfg

create_qpkg()
{
	QPKG_NAME=`/bin/cat qpkg.cfg |grep QPKG_NAME |cut -f 2 -d '"'` 
	QPKG_VER=`/bin/cat qpkg.cfg |grep QPKG_VER |cut -f 2 -d '"'`
	QPKG_PKG_FILE_NAME=${QPKG_NAME}-${QPKG_VER}.tgz

	if [ ${QPKG_HW_MODEL} = "all" ]; then
		QPKG_PKG_FINAL_QPKG_FILENAME=${QPKG_NAME}_${QPKG_VER}.qpkg
		QPKG_PKG_FINAL_ZIP_FILENAME=${QPKG_NAME}_${QPKG_VER}.zip
	elif [ ${QPKG_HW_MODEL} = "x86" ]; then
		QPKG_PKG_FINAL_QPKG_FILENAME=${QPKG_NAME}_${QPKG_VER}_x86.qpkg
		QPKG_PKG_FINAL_ZIP_FILENAME=${QPKG_NAME}_${QPKG_VER}_x86.zip
	elif [ ${QPKG_HW_MODEL} = "arm-x09" ]; then
		QPKG_PKG_FINAL_QPKG_FILENAME=${QPKG_NAME}_${QPKG_VER}_arm-x09.qpkg
		QPKG_PKG_FINAL_ZIP_FILENAME=${QPKG_NAME}_${QPKG_VER}_arm-x09.zip
	elif [ ${QPKG_HW_MODEL} = "arm-x19" ]; then
		QPKG_PKG_FINAL_QPKG_FILENAME=${QPKG_NAME}_${QPKG_VER}_arm-x19.qpkg
		QPKG_PKG_FINAL_ZIP_FILENAME=${QPKG_NAME}_${QPKG_VER}_arm-x19.zip
	fi 
	
	echo "Stage 1 - Compressing installation files... "
	mkdir temp;	cd temp
	rsync -qav --exclude=.svn ../$SRC_DIR_NAME/. .
	rsync -qav --exclude=.svn ../$SRC_DIR_NAME_SHARED/. .
	tar -czf ../$QPKG_NAME.tgz . --exclude-tag-all=all-wcprops
	cd ../
	rm -rf temp
	
	echo "Stage 2 - Inserting qinstall.sh..."
	tar -czf $QPKG_PKG_FILE_NAME $QPKG_INSTALL_SCRIPT $QPKG_NAME.tgz $QPKG_CFG_FILE
	rm -rf $QPKG_INSTALL_SCRIPT
	
	echo "Stage 3 - Adding encrypted header & wrapping up into .qpkg files..."
	/bin/mkdir -p ../../build
	$QPKG_PACKAGE_SCRIPT  ${QPKG_NAME} ${QPKG_PKG_FILE_NAME} ${QPKG_BUILTIN_SCRIPT} -f QNAPQPKG -v ${QPKG_VER}  2>/dev/null 1>/dev/null
	/bin/mv *.qpkg ../../build
	/bin/rm -rf *.tgz
	/bin/rm -rf qpkg.cfg
	
	echo "Stage 4 - Zipping & Finalising the QPKG ..."
	cd ../../build
	chmod +x ${QPKG_NAME}_${QPKG_VER}.qpkg
	mv ${QPKG_NAME}_${QPKG_VER}.qpkg $QPKG_PKG_FINAL_QPKG_FILENAME
	zip $QPKG_PKG_FINAL_ZIP_FILENAME $QPKG_PKG_FINAL_QPKG_FILENAME  2>/dev/null 1>/dev/null
	echo -e "\nDone! The QPKG is ready for install and publish in \"../../build/${QPKG_NAME}_${QPKG_VER}.[qpkg/zip]"\"
}

case "$1" in
  arm-x09)
		SRC_DIR_NAME=$SRC_DIR_NAME_X09	
		cp -af $QPKG_INSTALL_SCRIPT_ARM_X09 $QPKG_INSTALL_SCRIPT
		cp -af $QPKG_CFG_FILE_ARMX09 $QPKG_CFG_FILE
		NAS_MODELS=$ALL_ARM_BASED_X09_MODELS
		create_qpkg
	;;
	
  arm-x19)
		SRC_DIR_NAME=$SRC_DIR_NAME_X19
		cp -af $QPKG_INSTALL_SCRIPT_ARM_X19 $QPKG_INSTALL_SCRIPT
		NAS_MODELS=$ALL_ARM_BASED_X19_MODELS  
		cp -af $QPKG_CFG_FILE_ARMX19 $QPKG_CFG_FILE
		create_qpkg
	;;
	
  x86)
		SRC_DIR_NAME=$SRC_DIR_NAME_X39
		cp -af $QPKG_INSTALL_SCRIPT_X86_X39 $QPKG_INSTALL_SCRIPT
		NAS_MODELS=$ALL_X86_BASED_X39_MODELS  
		cp -af $QPKG_CFG_FILE_X86 $QPKG_CFG_FILE
		create_qpkg
	;;  

  all)
		SRC_DIR_NAME=$SRC_DIR_NAME_ALL
		cp -af $QPKG_INSTALL_SCRIPT_ALL $QPKG_INSTALL_SCRIPT
		NAS_MODELS=$ALL_MODELS
		cp -af $QPKG_CFG_FILE_ALL $QPKG_CFG_FILE
		create_qpkg
	;;
	
  *)
	echo "Usage: $0 {x09|x19|x39|all}"
	exit 1
esac  
  
 
