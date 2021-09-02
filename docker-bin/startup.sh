#!/bin/bash

THIS_SCRIPT_DIR=$(dirname $0)

# Set variables for application
source $THIS_SCRIPT_DIR/env.sh

echo "Start DBus"
dbus-daemon --system

echo "Start Datadog"
nohup /opt/datadog-agent/bin/agent/agent run -p /opt/datadog-agent/run/agent.pid > dd-agent.out &
nohup /opt/datadog-agent/embedded/bin/trace-agent --config /etc/datadog-agent/datadog.yaml --pid /opt/datadog-agent/run/trace-agent.pid > dd-trace.out &
nohup /opt/datadog-agent/embedded/bin/system-probe --config=/etc/datadog-agent/system-probe.yaml --pid=/opt/datadog-agent/run/system-probe.pid > dd-probe.out &
nohup /opt/datadog-agent/embedded/bin/process-agent --config=/etc/datadog-agent/datadog.yaml --sysprobe-config=/etc/datadog-agent/system-probe.yaml --pid=/opt/datadog-agent/run/process-agent.pid > dd-system-probe.out &

echo "Waiting for dependencies to properly start up - 240 seconds"
date
sleep 240

echo "Starting Appeals App"
date

echo "Waiting for Vacols to be ready"
rake local:vacols:wait_for_connection

echo "Creating DB in PG"
rake db:setup

echo "Seeding Facols"
rake local:vacols:seed

echo "Seeding DB in PG"
rake db:seed

echo "Enabling Feature Flags"
bundle exec rails runner scripts/enable_features_dev.rb

echo "Enabling caching"
touch tmp/caching-dev.txt

echo "Starting Caseflow App RoR"
rails server --binding 0.0.0.0 -p 3000
