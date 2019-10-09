---- The report attempts to show the status of all AMA Appeals in caseflow.

---- LIMITATIONS
-- This report may under count or overcount appeals in error states or extraordinary states. 
-- i.e. open root task with no active task; cases with multiple contridictory open tasks; etc.

---- Collecting each status & count
-- It is possible for some tasks to be worked simultaneously within a category, so we count distinct appeal ids rather than total number of tasks.

-- We define an appeal as 'Undistributed' based on the distribution task not yet being complete.
-- Undistributed appeals includes appeals actively waiting for evidence submission, actively in the hearings process, and those simply waiting for distribution
WITH undistributed_appeals AS (select '1. Not distributed'::text as decision_status, count(DISTINCT(appeal_id)) as num
            FROM tasks
            WHERE tasks.type IN ('DistributionTask')
              AND tasks.appeal_type='Appeal'
              AND tasks.status IN  ('on_hold', 'assigned', 'in_progress')
              AND tasks.appeal_id NOT IN (SELECT appeal_id FROM tasks WHERE tasks.appeal_type='Appeal' AND tasks.type = 'TimedHoldTask' AND tasks.status IN ('on_hold', 'assigned', 'in_progress'))
-- The Appeal has been distributed to the judge, but not yet assigned to an attorney for working.
      ), distributed_to_judge AS (select '2. Distributed to judge'::text as decision_status, count(DISTINCT(appeal_id)) as num
            FROM tasks
            WHERE tasks.type IN ('JudgeAssignTask') 
              AND tasks.appeal_type='Appeal'
              AND tasks.status IN  ('assigned', 'in_progress')
-- The Appeal has been assigned to the Attorney, but is not yet being worked.
      ), assigned_to_attorney AS (select '3. Assigned to attorney'::text as decision_status, count(DISTINCT(appeal_id)) as num
            FROM tasks
            WHERE tasks.type IN ('AttorneyTask', 'AttorneyRewriteTask') 
              AND tasks.appeal_type='Appeal'
              AND tasks.status IN  ('assigned')
-- The Appeal has been sent to VLJ Support
      ), assigned_to_colocated AS (select '4. Assigned to colocated'::text as decision_status, count(DISTINCT(appeal_id)) as num
            FROM tasks
            WHERE tasks.type IN ('AddressVerificationColocatedTask',
                                 'AojColocatedTask',
                                 'ArnesonColocatedTask',
                                 'ExtensionColocatedTask',
                                 'FoiaColocatedTask',
                                 'HearingClarificationColocatedTask',
                                 'IhpColocatedTask',
                                 'MissingHearingTranscriptsColocatedTask',
                                 'MissingRecordsColocatedTask',
                                 'NewRepArgumentsColocatedTask',
                                 'OtherColocatedTask',
                                 'PendingScanningVbmsColocatedTask',
                                 'PoaClarificationColocatedTask',
                                 'PreRoutingColocatedTask',
                                 'RetiredVljColocatedTask',
                                 'ScheduleHearingColocatedTask',
                                 'StayedAppealColocatedTask',
                                 'TranslationColocatedTask',
                                 'UnaccreditedRepColocatedTask')
              AND tasks.appeal_type='Appeal'
              AND tasks.status IN ('assigned', 'in_progress')
-- The Appeal has been assigned to the Attorney and is being worked.
      ), decision_in_progress AS (select '5. Decision in progress'::text as decision_status, count(DISTINCT(appeal_id)) as num
            FROM tasks
            WHERE tasks.type IN ('AttorneyTask', 'AttorneyRewriteTask') 
              AND tasks.appeal_type='Appeal'
              AND tasks.status IN  ('in_progress')
-- The Appeal decision has been written and is with the judge for sign off
      ), decision_ready_for_sign AS (select '6. Decision ready for signature'::text as decision_status, count(DISTINCT(appeal_id)) as num
            FROM tasks
            WHERE tasks.type IN ('JudgeDecisionReviewTask') 
              AND tasks.appeal_type='Appeal'
              AND tasks.status IN ('assigned', 'in_progress')
-- The Appeal has been signed by the judge and is in Quality Review or BVA Dispatch
      ), decision_signed AS (select '7. Decision signed'::text as decision_status, count(DISTINCT(appeal_id)) as num
            FROM tasks
            WHERE tasks.type IN ('BvaDispatchTask', 'QualityReviewTask') 
              AND tasks.appeal_type='Appeal'
              AND tasks.status IN ('assigned', 'in_progress')
-- The Appeal dispatch is completed. Case is complete with no open tasks.
      ), decision_dispatched AS (select '8. Decision dispatched'::text as decision_status, count(DISTINCT(appeal_id)) as num
            FROM tasks
            JOIN public.appeals AS appeals ON tasks.appeal_id = appeals.id  
            WHERE tasks.type IN ('BvaDispatchTask') 
              AND tasks.appeal_type='Appeal'
              AND tasks.status IN ('completed')
              AND tasks.appeal_id NOT IN (SELECT appeal_id FROM tasks WHERE tasks.appeal_type='Appeal' AND tasks.status IN ('on_hold', 'assigned', 'in_progress'))
-- The Appeal is currently on a timed hold
      ), appeal_on_hold AS (select 'ON HOLD'::text as decision_status, count(1) as num
            FROM tasks
            WHERE tasks.type IN ('TimedHoldTask') 
              AND tasks.appeal_type='Appeal'
              AND tasks.status IN ('assigned', 'in_progress')
-- An appeal can be considered cancelled if the RootTask is cancelled.
      ), appeal_cancelled AS (select 'CANCELLED'::text as decision_status, count(DISTINCT(appeal_id)) as num
            FROM tasks
            WHERE tasks.type IN ('RootTask')  
              AND tasks.appeal_type='Appeal'
              AND tasks.status IN ('cancelled')
-- Otherwise Unspecified Miscellaneous Status
-- The Appeal is currently returned from Quality Review (and with the Judge or Attorney) or returned from BVA Disptch (and with the Judge or Attorney)
-- Active task for MISC is one of: 'JudgeQualityReviewTask', 'JudgeDecisionReviewTask', 'AttorneyQualityReviewTask', 'AttorneyDecisionReviewTask'
      ), appeal_misc AS (select 'MISC'::text as decision_status, count(DISTINCT(appeal_id)) as num
            FROM tasks
            WHERE tasks.type IN ('JudgeQualityReviewTask', 'JudgeDispatchReturnTask', 'AttorneyQualityReviewTask', 'AttorneyDispatchReturnTask') 
              AND tasks.appeal_type='Appeal'
              AND tasks.status IN ('assigned', 'in_progress')

      )

---- Stitch together the temp tables into the format the Board would like

SELECT decision_status, num FROM undistributed_appeals
UNION ALL 
SELECT decision_status, num FROM distributed_to_judge
UNION ALL 
SELECT decision_status, num FROM assigned_to_attorney
UNION ALL 
SELECT decision_status, num FROM decision_in_progress
UNION ALL 
SELECT decision_status, num FROM assigned_to_colocated
UNION ALL 
SELECT decision_status, num FROM decision_ready_for_sign
UNION ALL 
SELECT decision_status, num FROM decision_signed
UNION ALL 
SELECT decision_status, num FROM decision_dispatched
UNION ALL 
SELECT decision_status, num FROM appeal_on_hold
UNION ALL 
SELECT decision_status, num FROM appeal_misc 
UNION ALL 
SELECT decision_status, num FROM appeal_cancelled
ORDER BY decision_status
