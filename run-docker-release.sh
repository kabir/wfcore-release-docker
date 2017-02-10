#!/bin/bash 

docker run \
	-v ~/.m2/settings.xml:/root/.m2/settings.xml \
	-v wfcore-release-maven-repo:/root/.m2 \
	-v  wfcore-release-checkouts:/checkouts \
	-v ~/.ssh:/root/.ssh \
	-it wildfly-core-build-temp \
	./do-release.sh $1 $2

