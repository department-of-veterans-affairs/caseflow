#!/bin/bash

# This script runs the WarRoom::DuppSuppClaimsSyncStatusUpdateCan job in the Caseflow Rails console.
# Usage: ./dupp-supp-claims-sync-status-update-can.sh <arg1> <arg2>
# where <arg1> is the first argument to pass to the job and <arg2> is the second argument.

set -e # Exit script immediately if any command exits with a non-zero status.

cd /opt/caseflow-certification/src

bin/rails runner 'WarRoom::DuppSuppClaimsSyncStatusUpdateCan.new.run(ARGV[0], ARGV[1])' "$1" "$2"

# Run the Rails console and execute the job.
bin/rails c <<EOF
begin
  x = WarRoom::DuppSuppClaimsSyncStatusUpdateCan.new
  x.run("$1", "$2")
rescue => e
  puts "Error: #{e.message}"
end
EOF
