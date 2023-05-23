#! /bin/bash
cd /opt/caseflow-certification/src; bin/rails c << DONETOKEN
RequestStore[:current_user] = User.system_user

vnu = vnu = WarRoom::OutcodeWithMismatchedVeteranName.new

vnu.run_remediation_by_veteran_id("$1")

DONETOKEN
