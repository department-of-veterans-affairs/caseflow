#!/bin/bash

THIS_SCRIPT_DIR=$(dirname $0)

# Set variables for application
source $THIS_SCRIPT_DIR/env.sh

echo "Waiting for dependencies to properly start up - 90 seconds"
sleep 90

echo "Starting Appeals App"
date

echo "Waiting for Vacols to be ready"
rake local:vacols:wait_for_connection

echo "Creating DB in PG"
rake db:setup

echo "Seeding Facols and Caseflow App"
rake local:vacols:seed

echo "Migrating the database"
rails db:migrate

echo "Seeding local caseflow database"
rake db:seed

echo "Enabling Feature Flags"
bundle exec rails runner scripts/enable_features_dev.rb

echo "Enabling caching"
touch tmp/caching-dev.txt

echo "Starting Caseflow App RoR"
rails server --binding 0.0.0.0 -p 3000
