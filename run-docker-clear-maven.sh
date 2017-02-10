#!/bin/bash 

LOCAL_MAVEN_TREE=/root/.m2/repository/org/wildfly

docker run \
	-v ~/.m2:/root/.m2 \
	-v wfcore-release-maven-repo:$LOCAL_MAVEN_TREE \
	-it wildfly-core-build-temp \
	./clean-volume.sh $LOCAL_MAVEN_TREE

