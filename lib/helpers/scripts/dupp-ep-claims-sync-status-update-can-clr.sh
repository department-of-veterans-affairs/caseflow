#!/bin/bash

# This script runs the WarRoom::DuppEpClaimsSyncStatusUpdateCanClr job in the Caseflow Rails console.
# Usage: ./dupp-ep-claims-sync-status-update-can-clr.sh <arg1> <arg2>
# This will check if the first and second arguments are either
# (Yes, No) for manual remediation or (No, Yes) for auto remediation.
# If they are not, it will print an error message
# and exit with a non-zero status.
# The first arguement is for manual remediation for HLR or Supplimental claim. The second argumentment is for auto-remediation for dupplicateEP error for HLR or SC.

set -e # Exit script immediately if any command exits with a non-zero status.

cd /opt/caseflow-certification/src/lib/helpers

bin/rails c <<DONETOKEN

if [[ "$1" == "No" && "$2" == "No" ]]; then
  echo "There is no remediation to be performed."
elif [[ "$1" == "Yes" && "$2" == "No" ]]; then
  echo "You chose the manual duplicateEP resolution for HLR or SC to be performed."
  bin/rails runner ActiveRecord::Base.transaction do; WarRoom::DuppEpClaimsSyncStatusUpdateCanClr.new.run("manual", "sc_hlr"); end
elif [[ "$1" == "No" && "$2" == "Yes" ]]; then
  echo "You chose the automated duplicateEP remediation for HLR and SC."
  bin/rails runner ActiveRecord::Base.transaction do; WarRoom::DuppEpClaimsSyncStatusUpdateCanClr.new.run("auto", "sc_hlr"); end
elif [[ "$1" == "Yes" && "$2" == "Yes" ]]; then
  echo "You cannot run both manual and auto remediations at the same time."
else
  echo "Invalid arguments. Please enter (Yes, No) for Manual Remediation or (No, Yes) for Auto Remediation."
fi

DONETOKEN
