# Base on the OpenJDK 8 image
FROM openjdk:8-jdk

# Download and extract maven into the image
RUN wget http://apache.mirror.anlx.net/maven/maven-3/3.3.9/binaries/apache-maven-3.3.9-bin.tar.gz && \
    tar -zxf apache-maven-3.3.9-bin.tar.gz && \
    cp -R apache-maven-3.3.9 /usr/local && \
    ln -s /usr/local/apache-maven-3.3.9/bin/mvn /usr/bin/mvn && \
    apt-get install git

#TODO Figure out how to mount the local maven repository, but somehow filter out the stuff built by this job

# Get a base version of wildfly-core 
#RUN git clone https://github.com/kabir/wildfly-legacy-test.git

#Add the script that will do the work
ADD container/clean-volume.sh /clean-volume.sh
ADD container/do-release.sh /do-release.sh
ADD container/file-util.sh /file-util.sh



