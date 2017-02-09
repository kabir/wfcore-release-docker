#!/bin/bash 

FROM_VERSION=$1
TO_VERSION=$2

if [ "x$FROM_VERSION" = "x" ]; then
	echo "No from version is set"
	exit 1
fi

if [ "x$TO_VERSION" = "x" ]; then
	echo "No to version is set"
	exit 1
fi	

echo Upgrading from $FROM_VERSION to $TO_VERSION 

# Go into the git checkout directory
cd /wildfly-legacy-test

# Update the sources
git fetch origin
git rebase origin/master

#TODO change the versions!

#TODO mount the real maven repository

# Do the build
mvn clean install

