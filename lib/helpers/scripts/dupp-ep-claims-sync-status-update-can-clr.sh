#!/bin/bash

# This script runs the WarRoom::DuppEpClaimsSyncStatusUpdateCanClr job in the Caseflow Rails console.
# Usage: ./dupp-ep-claims-sync-status-update-can-clr.sh <arg1> <arg2>
# This will check if the first and second arguments are either
# (manual, sc_hlr) for manual remediation or (auto, sc_hlr) for auto remediation.
# If they are not, it will print an error message
# and exit with a non-zero status.
# The first arguement is for manual remediation for HLR or Supplimental claim. The second argumentment is for auto-remediation for dupplicateEP error for HLR or SC.

set -e # Exit script immediately if any command exits with a non-zero status.

cd /opt/caseflow-certification/src; bin/rails c << DONETOKEN

x = WarRoom::DuppEpClaimsSyncStatusUpdateCanClr.new
x.run("$1", "$2")

DONETOKEN
