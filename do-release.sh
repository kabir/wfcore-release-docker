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

#Clean the built part of the maven repository
echo "Cleaning previously built stuff"
#TODO Renable this once we start doing the real core build
#rm -rfv /root/.m2/repository/org/wildfly/*

#Check that the checkouts folder was mapped, if not create a temo one and cd into it
if [ ! -d "/checkouts" ]; then
    echo "No checkouts folder was exists so creating a temp one. To cache this in the furure between all jobs:"
    echo "-Create a persistent docker volume which can be reused by running (this only needs doing once):"
    echo "  docker create --name wfcore-release-checkouts"
    echo "-Pass in the following parameter to docker run to reuse the checkouts folder:"
    echo "   -v wfcore-release-checkouts:/checkouts"
    mkdir /checkouts
fi
cd /checkouts

#Check if the wildfly-legacy-test checkout folder exists, and clone or update
if [ ! -d "/checkouts/wildfly-legacy-test" ]; then
    #TODO Try the ssh url
    echo "The wildfly-legacy-test checkout folder does not exist. Cloning git@github.com:wildfly/wildfly-legacy-test.git"
    git clone git@github.com:wildfly/wildfly-legacy-test.git
    cd wildfly-legacy-test
else
    echo "The wildfly-legacy-test checkout folder exists. Refreshing the latest"
    cd wildfly-legacy-test
    git reset --hard HEAD^
    git checkout master
    git fetch origin
    git reset --hard origin/master
fi

BRANCH_NAME=rel$TO_VERSION
#TODO this will give an error, but nothing serious if $BRANCH_NAME does not exist. It would be nice though to check somehow and only delete if it exists
git branch -D $BRANCH_NAME
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
git grep "\-SNAPSHOT"
echo ""
echo "=================================================================================================="
echo " Replacements made "
echo "=================================================================================================="
git --no-pager diff

# User input to verify it was correct
RESPONSE=""
while [ "x$RESPONSE" = "x" ]; do
    echo "Do the differences above look correct? (Y/N)"
    read RESPONSE
    if [ "$RESPONSE" = "N" ]; then
        echo "Exiting so you can investigate...."
        exit 1
    fi
    if [ "$RESPONSE" != "Y" ]; then
        echo "Unknown answer '$RESPONSE'"
        RESPONSE=""
    fi
done

# Do the build
echo ""
echo "=================================================================================================="
echo " Doing the build "
echo "=================================================================================================="
mvn clean install
