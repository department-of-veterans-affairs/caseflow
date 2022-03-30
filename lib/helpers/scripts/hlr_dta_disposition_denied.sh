# !/bin/bash
cd /opt/caseflow-certification/src; bin/rails c << DONETOKEN
x = WarRoom::HigherLevelReviewDutyToAssistDispositionDenied.new
x.run("$1")
DONETOKEN