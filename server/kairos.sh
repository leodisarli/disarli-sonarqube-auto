#!/bin/sh

echo "=============================" | tee -a ~/sonarqube/logs/log.txt
echo "Starting kairos" | tee -a ~/sonarqube/logs/log.txt
echo $(date) | tee -a ~/sonarqube/logs/log.txt
echo "Change to folder"
cd /home/mktzap/sonarqube/projects/kairos/
echo "Checkout master..."
git checkout master -q
echo "Fetch news..."
git fetch -q
echo "See if has news.."
LOCAL=$(git rev-parse @)
REMOTE=$(git rev-parse origin/master)
BASE=$(git merge-base @ origin/master)

if [ -z "$1" ]; then
    FORCE="t"
else
    FORCE="$1"
fi

if  [ $LOCAL = $REMOTE ] && [ "$FORCE" != "f" ]; then
    echo "Master is up-to-date no need to scan" | tee -a ~/sonarqube/logs/log.txt
elif [ $LOCAL = $BASE ] || [ "$FORCE" = "f" ] ; then
    echo "Need to pull. Pulling..."
    git pull
    echo "Stoping container"
    docker stop node8-for-test
    echo "Removing container"
    docker rm node8-for-test
    echo "Running tests"
    docker run --name node8-for-test --volume $(pwd):/usr/src leosarli/node8-for-test bash -c "npm install; npm run test; chown -R 1000:1000 coverage"
    echo "Stoping container"
    docker stop node8-for-test
    echo "Removing container"
    docker rm node8-for-test
    echo "Searching and replace paths on coverage files..."
    BASEDIR="/usr/src/"
    CHANGEDIR="./"
    sed -i 's!'$BASEDIR'!'$CHANGEDIR'!g' ./coverage/lcov.info
    echo "Removing docker Sonar image..."
    echo "Running Sonar..."
    sh /home/mktzap/sonarqube/sonar-scanner-3.3.0.1492-linux/bin/sonar-scanner
    echo $(date) | tee -a ~/sonarqube/logs/log.txt
    echo "Finished" | tee -a ~/sonarqube/logs/log.txt
elif [ $REMOTE = $BASE ]; then
    echo "Need to push! No way to Scan."
else
    echo "Diverged! No way to Scan."
fi
