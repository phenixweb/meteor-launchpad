#!/bin/bash

#
# builds a production meteor bundle directory
#
set -e

# set up npm auth token if one is provided
if [[ "$NPM_TOKEN" ]]; then
  echo "//registry.npmjs.org/:_authToken=$NPM_TOKEN" >> ~/.npmrc
fi

# Fix permissions warning in Meteor >=1.4.2.1 without breaking
# earlier versions of Meteor with --unsafe-perm or --allow-superuser
# https://github.com/meteor/meteor/issues/7959
export METEOR_ALLOW_SUPERUSER=true

cd $APP_SOURCE_DIR

# Install app deps
printf "\n[-] Running npm install in app directory...\n\n"
meteor npm install

# If we want to overwrite Cordova compatibility version, do it here
if [ -f $APP_SOURCE_DIR/launchpad.conf ]; then
  echo "\n[-] Export Cordova environment variables for Meteor mobile build (Hot code push)"
  source <(grep METEOR_CORDOVA_COMPAT_VERSION_IOS $APP_SOURCE_DIR/launchpad.conf)
  source <(grep METEOR_CORDOVA_COMPAT_VERSION_ANDROID $APP_SOURCE_DIR/launchpad.conf)
  source <(grep METEOR_CORDOVA_COMPAT_VERSION_EXCLUDE $APP_SOURCE_DIR/launchpad.conf)
  source <(grep AUTOUPDATE_VERSION $APP_SOURCE_DIR/launchpad.conf)
  export METEOR_CORDOVA_COMPAT_VERSION_IOS=$METEOR_CORDOVA_COMPAT_VERSION_IOS
  export METEOR_CORDOVA_COMPAT_VERSION_ANDROID=$METEOR_CORDOVA_COMPAT_VERSION_ANDROID
  export METEOR_CORDOVA_COMPAT_VERSION_EXCLUDE=$METEOR_CORDOVA_COMPAT_VERSION_EXCLUDE
  export AUTOUPDATE_VERSION=$AUTOUPDATE_VERSION
fi

# build the bundle
printf "\n[-] Building Meteor application...\n\n"
mkdir -p $APP_BUNDLE_DIR
meteor build --directory $APP_BUNDLE_DIR --server-only

# run npm install in bundle
printf "\n[-] Running npm install in the server bundle...\n\n"
cd $APP_BUNDLE_DIR/bundle/programs/server/
meteor npm install --production

# put the entrypoint script in WORKDIR
mv $BUILD_SCRIPTS_DIR/entrypoint.sh $APP_BUNDLE_DIR/bundle/entrypoint.sh

# change ownership of the app to the node user
chown -R node:node $APP_BUNDLE_DIR
