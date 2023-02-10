#! /bin/bash
cd /opt/caseflow-certification/src; bin/rails c << DONETOKEN
x = WarRoom::PayeeCodeUpdate.new
x.run("$1", "$2")
DONETOKEN