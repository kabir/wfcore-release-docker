#!/bin/bash 

CHECKOUTS_FOLDER=/checkouts

docker run \
	-v  wfcore-release-checkouts:$CHECKOUTS_FOLDER \
	-it wildfly-core-build-temp \
	./file-util.sh "ls" $1

