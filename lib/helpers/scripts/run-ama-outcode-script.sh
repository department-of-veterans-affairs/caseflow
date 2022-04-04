#! /bin/bash
cd /opt/caseflow-certification/src; bin/rails c << DONETOKEN
x = WarRoom::Outcode.new
x.ama_run("$1")
DONETOKEN

