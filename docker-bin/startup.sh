#!/bin/bash

THIS_SCRIPT_DIR=$(dirname $0)

# Set variables for application
source $THIS_SCRIPT_DIR/env.sh

# echo "Start DBus"
# dbus-daemon --system

# echo "############################################# Starting Appeals App #############################################"
# date

# echo "############################################# Waiting for Vacols to be ready #############################################"
# rake local:vacols:wait_for_connection
# echo "############################################# Vacols ready #############################################"

# echo "############################################# Creating DB in PG #############################################"
# bundle exec rake db:create:primary
# bundle exec rake db:schema:load:primary

# echo "############################################# Seeding Facols #############################################"
# rake local:vacols:seed

# echo "############################################# Seeding DB in PG #############################################"
# rake db:seed

# echo "############################################# Enabling Feature Flags #############################################"
# bundle exec rails runner scripts/enable_features_dev.rb

# echo "############################################# Enabling caching #############################################"
# touch tmp/caching-dev.txt

# echo "############################################# Initializing metabase #############################################"
# /caseflow/metabase/metabase_api_script_demo.sh

echo "############################################# Starting Caseflow App localhost:3000 #############################################"
rails server --binding 0.0.0.0 -p 3000
