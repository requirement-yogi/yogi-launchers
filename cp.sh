#!/bin/bash

# This script installs the plugin into all Confluence or Jira's /quickreload directories
# Which plugin? Either the one of the current directory, either the argument you pass
# in the command line. Example:
# cd plugins/confluence-app-1
# ../../cp.sh


PLUGIN="${1}"

set -u
set -e

if [[ -z "$PLUGIN" ]] ; then
    PLUGIN="$(basename $PWD)"
fi

# Go to the root directory if we are not there
cd "$(dirname "$0")"
GREEN_CHECKMARK="[\033[32m✔︎\033[0m]"
RED_MARK="[\033[31m✘\033[0m]"

# Search in various ways for the plugin that was requested by the user
if [[ -f "$PLUGIN" ]] ; then
    unzip -l "$PLUGIN" | grep -q "MANIFEST.MF"
elif [[ "$PLUGIN" == "--all" || "$PLUGIN" == "-all" ]] ; then
    PLUGIN=$(find plugins -type d -name "target" -maxdepth 2 -exec sh -c 'ls "{}"/*.jar 2>/dev/null' \; | sort -u)
    echo $PLUGIN
elif [[ ! -z "$PLUGIN" && -d "plugins/$PLUGIN" ]] ; then
    PLUGIN_JAR=$(find "plugins/$PLUGIN/target/" -name "*.jar" -print -quit)
    if [[ -z "$PLUGIN_JAR" ]] ; then
        echo "No JAR file found in plugins/$PLUGIN/target/"
        exit 1
    else
        PLUGIN="$(realpath "$PLUGIN_JAR")"
    fi
else
    echo
    echo "Copies the plugins' jars into the quickreload directories of each Confluence Docker installation,"
    echo "so that they get deployed."
    echo
    echo "Usage:"
    echo "    ./cp.sh (--all|confluence-app|path.jar|...)"
    echo
    echo "Prerequisites in Yogi's setup:"
    echo "- cp.sh is at the root of our repository,"
    echo "- plugins/ contain each of our plugin code (meaning the jars will be in plugins/confluence-app-1/target/confluence-app-1.jar),"
    echo "- The docker-compose.yml files are in the current directory tree, and they have a subdirectory named 'quickreload'. Example: launchers/confluence-9.0.1/quickreload/. To be clear in our true repository, the Docker scripts are placed in the subdirectory: launchers/build-image.sh and so on."
    echo "PLEASE ARRANGE THE SCRIPT ACCORDING TO YOUR NEEDS ;)"
    if [[ ! -z "$PLUGIN" ]] ; then
        echo -e "No such plugin: $PLUGIN $RED_MARK"
    fi
    exit 1
fi

DEPLOY_DIRECTORIES="$(find . -type d -name "quickreload" -maxdepth 3 | sort -u)"

FIRST=true
for FILE in $PLUGIN ; do
    echo "Deploying $FILE"
    if $FIRST ; then
        FIRST=false
    else
        sleep 2
    fi
    for DEPLOY_DIR in $DEPLOY_DIRECTORIES ; do
        # Our plugin names start with the name of the app they're made for.
        if [[ "$FILE" == *"jira-"* && "$DEPLOY_DIR" == *"/confluence-"*
            || "$FILE" == *"confluence-"* && "$DEPLOY_DIR" == *"/jira-"*
        ]] ; then
            echo "  to $DEPLOY_DIR [ SKIPPED ]"
            continue
        fi

        echo -n "  to $DEPLOY_DIR"
        cp "$FILE" "$DEPLOY_DIR/"
        echo -e " $GREEN_CHECKMARK"
    done
done
