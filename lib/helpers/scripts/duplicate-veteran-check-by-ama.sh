#! /bin/bash
cd /opt/caseflow-certification/src; bin/rails c << DONETOKEN
RequestStore[:current_user] = User.system_user

dvc = WarRoom::OutcodeWithDuplicateVeteran.new

dvc.run_check_by_ama_uuid("$1")

DONETOKEN