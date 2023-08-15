#! /bin/bash
cd /opt/caseflow-certification/src; bin/rails c << DONETOKEN
x = WarRoom::DtaDooDescriptionRemediationByReportLoad.new
x.run_by_report_load("$1", "$2")
DONETOKEN
