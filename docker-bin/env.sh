#!/bin/sh

# env vars required to run the appeals-app docker container on caseflowdemo

export POSTGRES_HOST=appeals-db
export POSTGRES_USER=postgres
export POSTGRES_PASSWORD=postgres
export RAILS_ENV=development
export DEPLOY_ENV=demo
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

export LD_PRELOAD=/usr/lib/x86_64-linux-gnu/libjemalloc.so
