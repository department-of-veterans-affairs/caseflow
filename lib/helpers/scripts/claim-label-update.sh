#!/usr/bin/env bash
if [ -z "$1" ]
  then
    echo "Expecting arguments claim id, old claim label, and correct claim label"
    exit 1
fi

if [ -z "$2" ]
  then
    echo "Expecting arguments claim id, old claim label, and correct claim label"
    exit 1
fi

if [ -z "$3" ]
  then
    echo "Expecting arguments claim id, old claim label, and correct claim label"
    exit 1
fi


cd /opt/caseflow-certification/src; bin/rails c << DONETOKEN

x = WarRoom::ClaimLabelChange.new
x.claim_label_updater("$1", "$2", "$3")
DONETOKEN