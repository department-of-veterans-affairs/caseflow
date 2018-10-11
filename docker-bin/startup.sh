#!/bin/bash

export POSTGRES_HOST=appeals-db
export POSTGRES_USER=postgres
export POSTGRES_PASSWORD=postgres
export RAILS_ENV=development
export NLS_LANG=AMERICAN_AMERICA.US7ASCII

export PATH=/.yarn/bin:/.config/yarn/global/node_modules/.bin:/usr/local/bundle/bin:/usr/local/bundle/gems/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/opt/oracle/instantclient_12_2

export LD_LIBRARY_PATH=/opt/oracle/instantclient_12_2
export ORACLE_HOME=/opt/oracle/instantclient_12_2

echo "Sleeping 200"
date
sleep 200
rake local:vacols:seed
#echo "done with rake"
#rails db:migrate
#echo "done with migrate"

#start the server
#rails s -p 3000