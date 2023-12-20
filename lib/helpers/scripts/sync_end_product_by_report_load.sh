#! /bin/bash
cd /opt/caseflow-certification/src; bin/rails c << DONETOKEN
x = WarRoom::ReportLoadEndProductSync.new
x.run_by_report_load("$1")
DONETOKEN
