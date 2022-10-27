#! /bin/bash
cd /opt/caseflow-certification/src; bin/rails c << DONETOKEN
RequestStore[:current_user] = User.system_user

dvc = dvc = WarRoom::OutcodeWithDuplicateVeteran.new

dvc.run_remediation_by_ama_appeals_uuid("$1")

DONETOKEN