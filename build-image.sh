#!/bin/bash

APP="$1"
LETTER="${APP:0:1}"
QR_VERSION="5.0.8"

if [[ "$APP" == "confluence" ]] ; then
    PORT_INTERNAL="8090"
elif [[ "$APP" == "jira" ]] ; then
    PORT_INTERNAL="8080"
fi

if [[ "$APP" == "confluence" && "$2" == "7.19."* ]] ; then
    PORT_HTTP="2000"
    PORT_DEBUG="5005"
    PORT_DB="5401"
    APP_VERSION="$2"
    JDK="jdk11"
    BASE_IMAGE="eclipse-temurin:11"
elif [[ "$APP" == "confluence" && "$2" == "8.5."* ]] ; then
    PORT_HTTP="2001"
    PORT_DEBUG="5006"
    PORT_DB="5402"
    APP_VERSION="$2"
    JDK="jdk11"
    BASE_IMAGE="eclipse-temurin:11"
elif [[ "$APP" == "confluence" && "$2" == "8.8."* ]] ; then
    PORT_HTTP="2002"
    PORT_DEBUG="5007"
    PORT_DB="5402"
    APP_VERSION="$2"
    JDK="jdk11"
    BASE_IMAGE="eclipse-temurin:11"
elif [[ "$APP" == "confluence" && "$2" == "8.9."* ]] ; then
    PORT_HTTP="2003"
    PORT_DEBUG="5008"
    PORT_DB="5403"
    APP_VERSION="$2"
    JDK="jdk17"
    BASE_IMAGE="eclipse-temurin:17"
elif [[ "$APP" == "confluence" && "$2" == "9.0."* ]] ; then
    PORT_HTTP="2004"
    PORT_DEBUG="5009"
    PORT_DB="5404"
    APP_VERSION="$2"
    JDK="jdk17"
    BASE_IMAGE="eclipse-temurin:17"
elif [[ "$APP" == "jira" && "$2" == "9.4."* ]] ; then
    PORT_HTTP="2005"
    PORT_DEBUG="5010"
    PORT_DB="5405"
    APP_VERSION="$2"
    JDK="jdk11"
    BASE_IMAGE="eclipse-temurin:11"
elif [[ "$APP" == "jira" && "$2" == "9.12."* ]] ; then
    PORT_HTTP="2006"
    PORT_DEBUG="5011"
    PORT_DB="5406"
    APP_VERSION="$2"
    JDK="jdk11"
    BASE_IMAGE="eclipse-temurin:11"
elif [[ "$APP" == "jira" && "$2" == "9.17."* ]] ; then
    PORT_HTTP="2008"
    PORT_DEBUG="5012"
    PORT_DB="5408"
    APP_VERSION="$2"
    # It seems Jira 9.15.0 and above were only published as JDK 11, surprisingly:
    # https://hub.docker.com/r/atlassian/jira-software/tags?page=&page_size=&ordering=&name=9.15.0-jdk
    JDK="jdk11"
    BASE_IMAGE="eclipse-temurin:11"
elif [[ "$APP" == "jira" && "$2" == "10.0."* ]] ; then
    PORT_HTTP="2009"
    PORT_DEBUG="5013"
    PORT_DB="5409"
    APP_VERSION="$2"
    JDK="jdk17"
    BASE_IMAGE="eclipse-temurin:17"
else
    echo "Usage: ./build-image.sh ( confluence | jira ) ( 7.19.0 | 8.5.0 | ...) [--apple|--apple-but-skip-building]"
    exit 1
fi

set -u
set -e

APPLE="false"
SKIP_BUILDING="false"
APPLE_SUFFIX=""
if [[ $# -eq 3 ]] ; then
    if [[ "$3" == "--apple" ]] ; then
        APPLE="true"
        APPLE_SUFFIX="-apple"
    elif [[ "$3" == "--apple-but-skip-building" ]] ; then
        APPLE="true"
        APPLE_SUFFIX="-apple"
        SKIP_BUILDING="true"
    fi
fi

echo "APP=$APP"
echo "LETTER=$LETTER"
echo "PORT_INTERNAL=$PORT_INTERNAL"
echo "PORT_HTTP=$PORT_HTTP"
echo "PORT_DEBUG=$PORT_DEBUG"
echo "PORT_DB=$PORT_DB"
echo "APP_VERSION=$APP_VERSION"
echo "JDK=$JDK"
echo "APPLE=$APPLE"
echo "SKIP_BUILDING=$SKIP_BUILDING"
echo "APPLE_SUFFIX=$APPLE_SUFFIX"
echo "BASE_IMAGE=$BASE_IMAGE"

#### First, download the jar

if [ ! -f "./docker/tmp/quickreload-${QR_VERSION}.jar" ] || [ ! -f "./docker/tmp/quickreload.properties" ] ; then

    QR_PATH="${HOME}/.m2/repository/com/atlassian/labs/plugins/quickreload/${QR_VERSION}/quickreload-${QR_VERSION}.jar"
    echo "Downloading quickreload-${QR_VERSION}.jar"

    [ -d "./docker/tmp" ] || mkdir -p docker/tmp

    if [ ! -f "${QR_PATH}" ] ; then
        mvn dependency:get \
            -Dartifact=com.atlassian.labs.plugins:quickreload:${QR_VERSION} \
            -Dtransitive=false
    fi

    cp ${QR_PATH} ./docker/tmp/quickreload-${QR_VERSION}.jar # Will be uploaded into the VM
    echo "/plugin" > ./docker/tmp/quickreload.properties # Necessary to build the image
fi


if [[ $APPLE == "true" && $SKIP_BUILDING == "false" ]] ; then

    echo "Rebuilding the Atlassian image, but for Apple silicon"

    if [[ "$APP" == "confluence" ]] ; then
        if [[ ! -d "./docker/tmp/confluence-docker-builder" ]] ; then
            cd docker/tmp
            git clone --recurse-submodule https://bitbucket.org/atlassian-docker/docker-atlassian-confluence-server.git confluence-docker-builder
        else
            cd docker/tmp/confluence-docker-builder
            git pull
        fi
        docker build --tag "atlassian/${APP}:${APP_VERSION}-${JDK}${APPLE_SUFFIX}" --build-arg CONFLUENCE_VERSION=$APP_VERSION --build-arg "BASE_IMAGE=${BASE_IMAGE}" .
        cd -

    elif [[ "$APP" == "jira" ]] ; then
        # Doesn't work? Check with https://github.com/collabsoft-net/example-jira-app-with-docker-compose/blob/AppleSilicon/start.sh
        if [[ ! -d "./docker/tmp/jira-docker-builder" ]] ; then
            cd docker/tmp
            git clone --recurse-submodule https://bitbucket.org/atlassian-docker/docker-atlassian-jira.git jira-docker-builder
        else
            cd docker/tmp/jira-docker-builder
            git pull
        fi
        #                                                                                             APP_VERSION <- May not be the right name. Is it JIRA_VERSION?
        docker build --tag "atlassian/jira-software:${APP_VERSION}-${JDK}${APPLE_SUFFIX}" --build-arg JIRA_VERSION=$APP_VERSION --build-arg "BASE_IMAGE=${BASE_IMAGE}" .
        cd -

    fi
fi

#### Build the image

cd docker
docker build \
    --build-arg "APP_VERSION=${APP_VERSION}" \
    --build-arg "JDK=${JDK}" \
    --build-arg "APPLE_SUFFIX=${APPLE_SUFFIX}" \
    --build-arg "QR_VERSION=${QR_VERSION}" \
    -t "yogi:${APP}-${APP_VERSION}${APPLE_SUFFIX}" \
    --file "Dockerfile-$APP" \
    .
cd -

#### Now, create a directory with a specific docker-compose.yml

export APP
export LETTER
export PORT_DEBUG
export PORT_DB
export PORT_HTTP
export APP_VERSION
export APPLE_SUFFIX
export APPLE_SUFFIX
export PORT_INTERNAL
export DOLLAR="$"
export QR_VERSION

FOLDER_NAME="${APP}-${APP_VERSION}${APPLE_SUFFIX}"

[ -d "./${FOLDER_NAME}" ] || mkdir ${FOLDER_NAME}
# It interprets the variables
envsubst < docker/docker-compose-template-${APP}.yml > ${FOLDER_NAME}/docker-compose.yml
envsubst < docker/app-nginx.conf > ${FOLDER_NAME}/app-nginx.conf

# Necessary to connect Confluence and Jira together
docker network create shared-network 2> /dev/null || true

echo
echo "Created: ${FOLDER_NAME}/docker-compose.yml"
echo

if ! grep -q "${LETTER}${APP_VERSION}\.local" /etc/hosts ; then
    echo "Missing entry in /etc/hosts: 127.0.0.1 ${LETTER}${APP_VERSION}.local"
fi
echo "cd ${FOLDER_NAME}"
echo "docker-compose up --detach"
echo "tail -f logs/atlassian-$APP.log"
echo "http://${LETTER}${APP_VERSION}.local:${PORT_HTTP}"
echo "Ready."
