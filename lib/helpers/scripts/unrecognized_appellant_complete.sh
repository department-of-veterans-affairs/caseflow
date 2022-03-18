#! /bin/bash
if [ -z "$1" ]
  then
    echo "Expecting argument representing the dispatch task id of the task with unrecognized appellant"
    exit 1
fi

 cd ~/appeals/caseflow; bin/rails c << DONETOKEN
  WarRoom::UnrecognizedAppellant.run_complete("$1")
DONETOKEN