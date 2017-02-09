# wfcore-release-docker
Docker job to do a wildfly-core release

This is currently very much work in progress. In fact it is not touching wildfly-core at all, rather another repository while I get used to Docker.

Setting up volumes
This is not totally necessary, but to speed things up so that we don't have to repopulate everything from scratch we can set up some volumes.
a) Set up a volume where the maven repository will live. This will be separate from your standard maven repository, and so may take some time to populate the first time you do a run, but should speed things up over the next runs. To set up the volume you do:
	```docker volume create --name wfcore-release-maven-repo```
b) Set up a volume where the maven repository will live. This will be separate from your standard maven repository, and so may take some time to populate the first time you do a run, but should speed things up over the next runs. To set up the volume you do:


```docker volume create --name wfcore-release-maven-repo```

To build the container:
	`docker build -t wildfly-core-build-temp .`
You need to build the container whenever the contents of this git repository are updated.

To run it:
	`docker run -v wfcore-release-maven-repo:/root/.m2 -v ~/.ssh:/root/.ssh -it wildfly-core-build-temp ./do-release.sh <SNAPSHOT-VERSION> <RELEASE-VERSION>`

There are other ways to map volumes as well, so please consult the documentation.
