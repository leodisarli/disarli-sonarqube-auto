#!/bin/sh

echo "=============================" | tee -a ~/sonarqube/logs/log.txt
echo "Starting kairos-publisher-php" | tee -a ~/sonarqube/logs/log.txt
echo $(date) | tee -a ~/sonarqube/logs/log.txt
echo "Change to folder"
cd /home/mktzap/sonarqube/projects/kairos-publisher-php/
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

if [ $LOCAL = $REMOTE ] && [ "$FORCE" != "f" ]; then
    echo "Master is up-to-date no need to scan" | tee -a ~/sonarqube/logs/log.txt
elif [ $LOCAL = $BASE ] || [ "$FORCE" = "f" ]; then
    echo "Need to pull. Pulling..."
    git pull
    echo "Stoping container"
    docker stop php71-for-test
    echo "Removing container"
    docker rm php71-for-test
    echo "Running container"
    docker run --name php71-for-test --volume $(pwd):/var/www/html leosarli/php71-for-test bash -c "composer install --prefer-dist; php ./vendor/bin/phpunit --coverage-html coverage --coverage-clover coverage/coverage.xml --log-junit coverage/junit.xml; chown -R 1000:1000 coverage"
    echo "Stoping container"
    docker stop php71-for-test
    echo "Removing container"
    docker rm php71-for-test
    echo "Searching and replace paths on coverage files..."
    BASEDIR="/var/www/html/"
    CHANGEDIR="./"
    sed -i 's!'$BASEDIR'!'$CHANGEDIR'!g' ./coverage/coverage.xml
    sed -i 's!'$BASEDIR'!'$CHANGEDIR'!g' ./coverage/junit.xml
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
