#! /bin/bash
if [ -z "$1" ]
  then
    echo "Expecting arguments, hearing vacols id and new appeal vacols id"
    exit 1
fi

if [ -z "$2" ]
  then
    echo "Expecting arguments, hearing vacols id and new appeal vacols id"
    exit 1
fi

cd /opt/caseflow-certification/src; bin/rails c << DONETOKEN
script = WarRoom::HearingsInfoMigration.new
script.move_legacy_hearing("$1", "$2")
DONETOKEN