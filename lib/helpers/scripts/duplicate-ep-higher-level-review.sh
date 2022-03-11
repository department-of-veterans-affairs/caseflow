cd /opt/caseflow-certification/src; bin/rails c << DONETOKEN
x = WarRoom::OutcodeWithDuplicateEP.new
x.higher_level_review_duplicate_ep("$1")
DONETOKEN