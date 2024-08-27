#! /bin/bash
cd /opt/caseflow-certification/src; bin/rails c << DONETOKEN
x = MissingVacolsHearingJobFix.new
x.perform
DONETOKEN
