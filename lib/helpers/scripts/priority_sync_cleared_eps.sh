#! /bin/bash
cd /opt/caseflow-certification/src; bin/rails c << DONETOKEN
x = WarRoom::ReportLoadEndProductSync.new
x.run_for_cleared_eps("$1")
DONETOKEN
