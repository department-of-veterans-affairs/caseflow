#! /bin/bash
if [ -z "$1" ]
  then
    echo "Expecting argument representing the dispatch task id of the task with unrecognized appellant"
    exit 1
fi

cd /opt/caseflow-certification/src; bin/rails c << DONETOKEN
  WarRoom::UnrecognizedAppellant.run("$1")
DONETOKEN
