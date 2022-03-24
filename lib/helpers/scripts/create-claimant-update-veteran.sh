#!/usr/bin/env bash
if [ -z "$1" ]
  then
    echo "Expecting arguments claim id, participant id, and payee_code"
    exit 1
fi

if [ -z "$2" ]
  then
    echo "Expecting arguments claim id, participant id, and payee_code"
    exit 1
fi

if [ -z "$3" ]
  then
    echo "Expecting arguments claim id, participant id, and payee_code"
    exit 1
fi


cd /opt/caseflow-certification/src; bin/rails c << DONETOKEN

x = WarRoom::CreateClaimant.new
x.CreateVeteranClaimant("$1", "$2", "$3")
DONETOKEN