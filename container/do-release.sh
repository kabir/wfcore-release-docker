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

GITHUB_REPO=git@github.com:kabir


echo Upgrading from $FROM_VERSION to $TO_VERSION

#Check that the checkouts folder was mapped, if not create a temp one and cd into it
if [ ! -d "/checkouts" ]; then
    echo "No checkouts folder was exists so creating a temp one. To cache this in the furure between all jobs:"
    echo "-Create a persistent docker volume which can be reused by running (this only needs doing once):"
    echo "  docker create --name wfcore-release-checkouts"
    echo "-Pass in the following parameter to docker run to reuse the checkouts folder:"
    echo "   -v wfcore-release-checkouts:/checkouts"
    mkdir /checkouts
fi
cd /checkouts



#Check if the wildfly checkout folder exists, and clone or update
if [ ! -d "/checkouts/wildfly" ]; then
    echo "The wildfly checkout folder does not exist. Cloning $GITHUB_REPO/wildfly.git"
    git clone $GITHUB_REPO/wildfly.git
fi


#Check if the wildfly-core checkout folder exists, and clone or update
if [ ! -d "/checkouts/wildfly-core" ]; then
    echo "The wildfly-core checkout folder does not exist. Cloning $GITHUB_REPO/wildfly-core.git"
    git clone $GITHUB_REPO/wildfly-core.git
    cd wildfly-core
else
    echo "The wildfly-core checkout folder exists. Refreshing the latest"
    cd wildfly-core
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


echo ""
echo "=================================================================================================="
echo " Replacements made "
echo "=================================================================================================="
git --no-pager diff

# User input to verify it was correct
RESPONSE=""
while [ "x$RESPONSE" = "x" ]; do
    echo "Do the replacements made above look correct? (Y/N)"
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

#Run the build with all the flags set

# !!!!!!!!
# !!!! TODO get rid of -Dmaven.test.failureignore   !!!!
# Or we will never get an error. Instead we should patch the four tests failing from running under root with
# Assume.assumeFalse(System.hasProperty("wildfly.docker.release")
#
# The -Dwildfly.docker.release property is to conditionally ignore tests which assume not running as root
mvn clean install -Dwildfly.docker.release -Pjboss-release -Prelease -DallTests--fail-at-end -Dmaven.test.failure.ignore

BUILD_STATUS=$?
if [ $BUILD_STATUS != 0 ]; then
    echo "=================================================================================================="
    echo " Build failed "
    echo "  ./run-docker-ls.sh <dir>"
    echo "and"
    echo "  ./run-docker-more.sh <dir>"
    echo "from another terminal window to get more information about the failures."
    echo "Then enter 'Y' to proceed with the release, or 'N' to abort:"
    echo "=================================================================================================="

    RESPONSE=""
    while [ "x$RESPONSE" = "x" ]; do
        read RESPONSE
        if [ "$RESPONSE" = "N" ]; then
            exit $BUILD_STATUS
        fi
        if [ "$RESPONSE" != "Y" ]; then
            echo "Unknown answer '$RESPONSE'. Enter 'Y' to proceed with the release, or 'N' to abort:"
            RESPONSE=""
        fi
    done
fi

exit 1


echo ""
echo "=================================================================================================="
echo " Verifying WildFly Full still builds"
echo "=================================================================================================="

# Refresh WildFly to make sure we have the latest
cd ../wildfly
git reset --hard HEAD^
git checkout master
git fetch origin
git reset --hard origin/master
cd ..
# Build WildFly skipping tests, but overriding the core version
mvn clean install -DallTests -DskipTests -Dversion.org.wildfly.core=$TO_VERSION
BUILD_STATUS=$?
if [ $BUILD_STATUS != 0 ]; then
    exit $BUILD_STATUS
fi


echo ""
echo "=================================================================================================="
echo " Committing the wildfly-core changes, and pushing to the upstream $BRANCH_NAME branch"
echo "=================================================================================================="
cd ../wildfly-core
git commit -am "Prepare for the $TO_VERSION release"
git push origin $BRANCH_NAME
git checkout master
git merge --ff-only $BRANCH_NAME


echo ""
echo "=================================================================================================="
echo " Deploying the core release to the staging repository"
echo "=================================================================================================="

# Deploy the core release to the staging repository
mvn deploy -Pjboss-release -Prelease -DallTests -DskipTests
BUILD_STATUS=$?
if [ $BUILD_STATUS != 0 ]; then
    exit $BUILD_STATUS
fi

# Action needed to close the repository
echo ""
echo "=================================================================================================="
echo "Now close the staging repository on nexus, and release it."
echo "=================================================================================================="
RESPONSE=""
while [ "x$RESPONSE" = "x" ]; do
    echo "Once it has been released enter 'Y' to continue performing the tag. To exit enter 'N':"
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



# Blow away the wildfly core artifacts and rebuild full.
echo ""
echo "=================================================================================================="
echo "Deleting all wildfly-core artifacts from the local maven repository, and rebuilding full."
echo "=================================================================================================="
rm -rf /root/.m2/repository/org/wildfly/core
cd ../wildfly
mvn install -DallTests -DskipTests -Dversion.org.wildfly.core=$TO_VERSION
BUILD_STATUS=$?
if [ $BUILD_STATUS != 0 ]; then
    exit $BUILD_STATUS
fi

echo ""
echo "=================================================================================================="
echo "Push the tag"
echo "=================================================================================================="
cd ../wildfly-core
git tag $TO_VERSION
BUILD_STATUS=$?
if [ $BUILD_STATUS != 0 ]; then
    exit $BUILD_STATUS
fi
git push origin master --tags
BUILD_STATUS=$?
if [ $BUILD_STATUS != 0 ]; then
    exit $BUILD_STATUS
fi

echo ""
echo "=================================================================================================="
echo "All Done!!! Well, ALMOST...."
echo "=================================================================================================="
echo "See https://developer.jboss.org/wiki/WildFlyCoreReleaseProcess"
echo "1) Now open a WildFly pull request upgrading the wildfly-core version to $TO_VERSION"
echo "2) Update wildfly-core master to the next -SNAPSHOT version"
echo "3) Cleanup/release Jira, and add the next fix version"
echo "4) Update the CI jobs"


