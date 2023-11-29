#! /bin/bash
cd /opt/caseflow-certification/src; bin/rails c << DONETOKEN
x = WarRoom::RemandDtaOrDooHigherLevelReview.new
x.run_by_report_load("$1", "$2")
DONETOKEN
