# wfcore-release-docker
Docker job to do a wildfly-core release

This is currently very much work in progress. In fact it is not touching wildfly-core at all, rather another repository while I get used to Docker.

To run it:
	`docker run wildfly-core-build-temp ./do-release.sh <SNAPSHOT-VERSION> <RELEASE-VERSION>`
