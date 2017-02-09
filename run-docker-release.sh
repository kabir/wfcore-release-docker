#!/bin/bash 

docker run \
	-v ~/.m2:/root/.m2 \
	-v wfcore-release-maven-repo:/root/.m2/repository/org/wildfly \
	-v  wfcore-release-checkouts:/checkouts \
	-v ~/.ssh:/root/.ssh \
	-it wildfly-core-build-temp \
	./do-release.sh $1 $2

