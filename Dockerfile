# To run this docker image
#
#   docker run wildfly-core-build-temp ./do-release.sh <SNAPSHOT-VERSION> <RELEASE-VERSION>


# Base on the OpenJDK 8 image
FROM openjdk:8-jdk

# Download and extract maven into the image
RUN wget http://apache.mirror.anlx.net/maven/maven-3/3.3.9/binaries/apache-maven-3.3.9-bin.tar.gz
RUN tar -zxf apache-maven-3.3.9-bin.tar.gz
RUN cp -R apache-maven-3.3.9 /usr/local
RUN ln -s /usr/local/apache-maven-3.3.9/bin/mvn /usr/bin/mvn

# Install git into the image
RUN apt-get install git

#TODO Figure out how to mount the local maven repository, but somehow filter out the stuff built by this job

# Get a base version of wildfly-core 
RUN git clone https://github.com/kabir/wildfly-legacy-test.git

ADD do-release.sh /do-release.sh




