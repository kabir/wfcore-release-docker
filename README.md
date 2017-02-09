# wfcore-release-docker
Docker job to do a wildfly-core release

This is currently very much work in progress. In fact it is not touching wildfly-core at all, rather another repository while I get used to Docker.

First you need to build the image by starting up your Docker daemon, and executing
    `docker build -t wildfly-core-build-temp .`
Whenever the contents of this git repository are updated you will need to rebuild the image.

To speed things up when running the container we do some volume mapping, so that we don't have to repopulate everything from scratch each time we run a build. Some of these mappings require persistent docker volumes. The `run-docker-release.sh` script does all the passing of parameters, but I will list them here:

    * `-v ~/.m2:/root/.m2` - The docker image will by default use `/root/.m2` as its maven home folder. This command maps the host OS's `~/.m2` folder to that. This means that we can run builds quickly without having to download the world every time we run a build. Also we use our settings.xml.
    * `-v wfcore-release-maven-repo:/root/.m2/repository/org/wildfly` - However, since this build works on artifacts under `org/wildfly`, and we don't want to pollute the host maven repository with these, we override the mapping for this sub-folder tree. `wfcore-release-maven-repo` is a docker persistent volume which is reused between builds. It needs to be created only once (although you can delete it and recreate it) by running `docker volume create --name wfcore-release-maven-repo`. All writes under this location will end up in this Docker volume rather than in your main maven repository, so you can happily run this container while doing builds in your main OS - without the two interfering! 
    * `-v wfcore-release-checkouts:/checkouts` - To avoid having to wait for a lengthy checkout process, we map the `wfcore-release-checkouts` docker persistent volume to a folder within docker called `/checkouts`. It needs to be created only once (although you can delete it and recreate it) by running `docker volume create --name wfcore-release-checkouts`. The first time the image is used, it will do a `git clone`, and on subsequent runs it will do a `git fetch` and then reset the branch to the latest.
    * `	-v ~/.ssh:/root/.ssh` - maps your local `~/.ssh` folder to Docker's `/root/.ssh` folder so that we can push to github.
    * `	-it wildfly-core-build-temp` - specifies the name of the image to use when running the container. I think the `-i` means 'interactive' so that the user can input data into the docker terminal (the script gives some prompts at some stages).


To do a release you run this script:
	`./run-docker-release.sh <SNAPSHOT_VERSION> <RELEASE_VERSION>` 

