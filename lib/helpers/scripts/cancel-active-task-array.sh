#! /bin/bash
if [ -z "$1" ]
  then
    echo "Expecting a specifc assigned_to_id argument FROM cancel_active_task_array_v1.rb"
    exit 1
fi
if [ -z "$2" ]
  then
    echo "Expecting a specific task_type argument of FROM cancel_active_task_array_v1.rb"
    exit 1
fi
cd /opt/caseflow-certification/src; bin/rails c
#tee cancel_active_task_array-$(date +%m%d%Y).log *****in prod this is different.
<< DONETOKEN
x = WarRoom::CancelActiveTaskArray.new
x.run("$1", "$2")
DONETOKEN
