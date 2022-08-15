#! /bin/bash
if [ -z "$1" ]
  then
    echo "Expecting arguments, hearing uuid and destination appeal uuid"
    exit 1
fi

if [ -z "$2" ]
  then
    echo "Expecting arguments, hearing uuid and destination appeal uuid"
    exit 1
fi

cd /opt/caseflow-certification/src; bin/rails c << DONETOKEN
script = WarRoom::HearingsInfoMigration.new
script.duplicate_ama_hearing("$1", "$2")
DONETOKEN