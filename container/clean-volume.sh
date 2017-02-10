#!/bin/bash 

CLEAN_FOLDER=$1

if [ "x$CLEAN_FOLDER" = "x" ]; then
	echo "No folder to clean is set"
	exit 1
fi

if [ ! -d "$CLEAN_FOLDER" ]; then
    echo "The folder $CLEAN_FOLDER does not exist"
fi


echo ""
echo "=================================================================================================="
echo " Cleaning $CLEAN_FOLDER"
echo "=================================================================================================="
cd $CLEAN_FOLDER
rm -rfv *
echo ""
echo "=================================================================================================="
echo " Cleaning $CLEAN_FOLDER"
echo "=================================================================================================="
ls -al

exit 0
