#!/bin/bash

# Variables for application
export POSTGRES_HOST=appeals-db
export POSTGRES_USER=postgres
export POSTGRES_PASSWORD=postgres
export RAILS_ENV=development
export NLS_LANG=AMERICAN_AMERICA.US7ASCII
export REDIS_URL_CACHE=redis://appeals-redis:6379/0/cache/
export REDIS_URL_SIDEKIQ=redis://appeals-redis:6379

export PATH=/.yarn/bin:/.config/yarn/global/node_modules/.bin:/usr/local/bundle/bin:/usr/local/bundle/gems/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/opt/oracle/instantclient_12_2

export LD_LIBRARY_PATH=/opt/oracle/instantclient_12_2
export ORACLE_HOME=/opt/oracle/instantclient_12_2

echo "Sleeping 150"
date
sleep 150

echo "Creating DB in PG"
rake db:setup

echo "Seeding Facols and Caseflow App"
rake local:vacols:seed

echo "Migrating the database"
rails db:migrate

echo "Starting Caseflow App RoR"
rails server --binding 0.0.0.0 -p 3000