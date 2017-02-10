#!/bin/bash 

COMMAND=$1
TARGET_FILE=$2

if [ "x$COMMAND" = "x" ]; then
	echo "No command was set"
	exit 1
fi

if [ "x$TARGET_FILE" = "x" ]; then
	echo "No file was set"
	exit 1
fi



echo ""
echo "=================================================================================================="
echo " Running $COMMAND $TARGET_FILE"
echo "=================================================================================================="
$COMMAND $TARGET_FILE

exit 0
