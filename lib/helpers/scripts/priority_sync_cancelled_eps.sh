#! /bin/bash
cd /opt/caseflow-certification/src; bin/rails c << DONETOKEN
x = WarRoom::ReportLoadEndProductSync.new
x.run_for_cancelled_eps("$1", "$2")
DONETOKEN
