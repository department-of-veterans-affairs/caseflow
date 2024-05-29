#! /bin/bash
cd /opt/caseflow-certification/src; bin/rails c << DONETOKEN
x = WarRoom::PreDocketIhpTasks.new
x.run("$1")
DONETOKEN

