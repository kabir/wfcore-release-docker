#!/bin/bash 

FROM_VERSION=$1
TO_VERSION=$2
GITHUB_USER=$3

if [ "x$FROM_VERSION" = "x" ]; then
	echo "No from version is set"
	exit 1
fi

if [ "x$TO_VERSION" = "x" ]; then
	echo "No to version is set"
	exit 1
fi

echo Upgrading from $FROM_VERSION to $TO_VERSION

BRANCH_NAME=rel$TO_VERSION

# Clone the github repository and checkout a branch on which to do the release
# TODO Use the ssh key from the local filesystem and use the ssh url git@github.com:wildfly/wildfly-legacy-test.git
git clone https://github.com/wildfly/wildfly-legacy-test.git
cd /wildfly-legacy-test
git checkout -b $BRANCH_NAME
git status

# Change the versions!
FROM_COUNT=`git grep "$FROM_VERSION" | wc -l`
if [ $FROM_COUNT -lt 10 ]; then
    echo "Only $FROM_COUNT references to $FROM_VERSION were found in exisiting poms. As a sanity check we look for at least five of those. Make sure you used the correct 'from' version."
    echo "Searching for -SNAPSHOT in main pom.xml:"
    git grep "\-SNAPSHOT" pom.xml
    exit 1
fi

echo "Found $FROM_COUNT occurrences of $FROM_VERSION in poms..."

# Now replace the versions in the poms
echo ""
echo "=================================================================================================="
echo " Replacing $FROM_VERSION with $TO_VERSION in the poms"
echo "=================================================================================================="
find . -type f -name "pom.xml" -print0 | xargs -0 -t sed -i "" -e 's/$FROM_VERSION/$TO_VERSION/g'
find . -type f -name "pom.xml" -print0 | xargs -0 -t sed -i "" -e "s/$FROM_VERSION/$TO_VERSION/g"
echo ""
echo "=================================================================================================="
echo " Modified files"
echo "=================================================================================================="
git status
echo ""
echo "=================================================================================================="
echo " Remaining -SNAPSHOT versions"
echo "=================================================================================================="
echo ""
git grep "\-SNAPSHOT"


# TODO I cannot get the read command to work when running in docker, so I can't get user input
# User input to verify it was correct, or to inspect
#echo "Do the differences above look correct? Enter [Y]es, [N]o or [I]nspect:"
#read RESPONSE
#echo answer was $RESPONSE

#TODO mount the real maven repository

# Do the build
echo "skipping doing the build for now"
#mvn clean install

