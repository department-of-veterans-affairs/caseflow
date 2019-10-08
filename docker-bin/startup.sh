#!/bin/bash

# Variables for application
export POSTGRES_HOST=appeals-db
export POSTGRES_USER=postgres
export POSTGRES_PASSWORD=postgres
export RAILS_ENV=development
export NLS_LANG=AMERICAN_AMERICA.US7ASCII
export REDIS_URL_CACHE=redis://appeals-redis:6379/0/cache/
export REDIS_URL_SIDEKIQ=redis://appeals-redis:6379
# envs to make development work in docker without affecting other devs
export DOCKERIZED=true
export DEMO_PORT=1521
export DEMO_DB="(DESCRIPTION=
    (ADDRESS_LIST=(ADDRESS=(PROTOCOL=tcp)(HOST=VACOLS_DB-development)(PORT=1521)))(RECV_TIMEOUT=120)(SEND_TIMEOUT=5)(CONNECT_DATA=(SID=BVAP)))"
    

export PATH=/.yarn/bin:/.config/yarn/global/node_modules/.bin:/usr/local/bundle/bin:/usr/local/bundle/gems/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/opt/oracle/instantclient_12_2

export LD_LIBRARY_PATH=/opt/oracle/instantclient_12_2
export ORACLE_HOME=/opt/oracle/instantclient_12_2

echo "Waiting for FACOLS to properly start up - 4 minutes"
sleep 240

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

echo "Starting Caseflow App RoR"
rails server --binding 0.0.0.0 -p 3000
