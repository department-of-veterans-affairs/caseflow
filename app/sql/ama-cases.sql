SELECT CAST("Appeals"."docket_number" AS TEXT) AS "docket_number",
  "Appeals"."id" AS "id",
  CAST("Appeals"."veteran_file_number" AS TEXT) AS "veteran_file_number",
  "Appeals"."receipt_date" AS "receipt_date",
  CAST("Appeals"."docket_type" AS TEXT) AS "docket_type",
  "Appeals"."established_at" AS "established_at",
  "Appeals"."uuid" AS "uuid",
  "Appeals"."legacy_opt_in_approved" AS "legacy_opt_in_approved",
  "Appeals"."veteran_is_not_claimant" AS "veteran_is_not_claimant",
  "Appeals"."establishment_submitted_at" AS "establishment_submitted_at",
  "Appeals"."establishment_processed_at" AS "establishment_processed_at",
  "Appeals"."establishment_attempted_at" AS "establishment_attempted_at",
  CAST("Appeals"."establishment_error" AS TEXT) AS "establishment_error",
  "Appeals"."establishment_last_submitted_at" AS "establishment_last_submitted_at",
  "Appeals"."attorney_task_id" AS "attorney_task_id",
  CAST("Appeals"."attorney_task_status" AS TEXT) AS "attorney_task_status",
  "Appeals"."attorney_task_status_started_date" AS "attorney_task_status_started_date",
  "Appeals"."attorney_task_status_assigned_date" AS "attorney_task_status_assigned_date",
  CAST("Appeals"."judge_task_status" AS TEXT) AS "judge_task_status",
  CAST("Appeals"."judge_assign_task_status" AS TEXT) AS "judge_assign_task_status",
  "Appeals"."judge_assign_task_status_assigned_date" AS "judge_assign_task_status_assigned_date",
  "Appeals"."judge_assign_task_status_started_date" AS "judge_assign_task_status_started_date",
  "Appeals"."judge_assign_task_status_completed_date" AS "judge_assign_task_status_completed_date",
  CAST("Appeals"."judge_decision_review_task_status" AS TEXT) AS "judge_decision_review_task_status",
  "Appeals"."judge_decision_review_task_status_assigned_date" AS "judge_decision_review_task_status_assigned_date",
  "Appeals"."judge_decision_review_task_status_started_date" AS "judge_decision_review_task_status_started_date",
  "Appeals"."judge_decision_review_task_status_completed_date" AS "judge_decision_review_task_status_completed_date",
  CAST("Appeals"."quality_review_task_status" AS TEXT) AS "quality_review_task_status",
  "Appeals"."attorney_id" AS "attorney_id",
  CAST("Appeals"."attorney_name" AS TEXT) AS "attorney_name",
  "Appeals"."attorney_vacols_sattyid" AS "attorney_vacols_sattyid",
  "Appeals"."judge_vacols_sattyid" AS "judge_vacols_sattyid",
  "Appeals"."judge_id" AS "judge_id",
  CAST("Appeals"."judge_name" AS TEXT) AS "judge_name",
  CAST("Appeals"."bva_dispatch_task_status" AS TEXT) AS "bva_dispatch_task_status",
  CAST("Appeals"."distribution_task_status" as TEXT) AS "distribution_task_status",
  CAST("Appeals"."root_task_status" as TEXT) AS "root_task_status",
  CAST("Appeals"."misc_task_status" as TEXT) AS "misc_task_status",
  CAST("Appeals"."timed_hold_task_status" as TEXT) AS "timed_hold_task_status",
  "Appeals"."bva_dispatch_task_status_completed_date" AS "bva_dispatch_task_status_completed_date",
  "Appeals"."appeal_task_status.decision_status" AS "appeal_task_status.decision_status",
  "Appeals"."appeal_task_status.decision_status__sort_" AS "appeal_task_status.decision_status__sort_",
  "Appeals"."appeal_task_status.decision_signed_by_judge" AS "appeal_task_status.decision_signed_by_judge",
  "Appeals"."appeal_task_status.case_completed_by_attorney" AS "appeal_task_status.case_completed_by_attorney",
  "Judge"."id" AS "id (users)",
  CAST("Judge"."station_id" AS TEXT) AS "station_id",
  CAST("Judge"."css_id" AS TEXT) AS "css_id",
  CAST("Judge"."full_name" AS TEXT) AS "full_name",
  CAST("Judge"."email" AS TEXT) AS "email",
  CAST("Judge"."roles" AS TEXT) AS "roles",
  CAST("Judge"."selected_regional_office" AS TEXT) AS "selected_regional_office",
  "Attorney"."id" AS "id (users) #1",
  CAST("Attorney"."station_id" AS TEXT) AS "station_id (users)",
  CAST("Attorney"."css_id" AS TEXT) AS "css_id (users)",
  CAST("Attorney"."full_name" AS TEXT) AS "full_name (users)",
  CAST("Attorney"."email" AS TEXT) AS "email (users)",
  CAST("Attorney"."roles" AS TEXT) AS "roles (users)",
  CAST("Attorney"."selected_regional_office" AS TEXT) AS "selected_regional_office (users)",
  "Veteran"."id" AS "id (veterans)",
  CAST("Veteran"."file_number" AS TEXT) AS "file_number",
  CAST("Veteran"."participant_id" AS TEXT) AS "participant_id",
  CAST("Veteran"."first_name" AS TEXT) AS "first_name",
  CAST("Veteran"."last_name" AS TEXT) AS "last_name",
  CAST("Veteran"."middle_name" AS TEXT) AS "middle_name",
  CAST("Veteran"."name_suffix" AS TEXT) AS "name_suffix",
  CAST("Veteran"."closest_regional_office" AS TEXT) AS "closest_regional_office",
  "AOD Details"."appeals.id" AS "aod_appeals.id",
  "AOD Details"."granted" AS "aod_granted",
  "AOD Details"."reason" AS "aod_reason",
  "AOD Details"."veteran.age" AS "aod_veteran.age",
  "AOD Details"."is_advanced_on_docket" AS "aod_is_advanced_on_docket"
FROM (
  WITH appeal_task_status AS (SELECT *,
      (select tasks.status
        FROM tasks  AS tasks
        where tasks.appeal_id = appeals.id AND tasks.type = 'RootTask'
        limit 1
      ) as root_task_status,
      (select tasks.status
        FROM tasks  AS tasks
        where tasks.appeal_id = appeals.id AND tasks.type = 'DistributionTask'
        limit 1
      ) as distribution_task_status,
      (select tasks.status
        FROM tasks  AS tasks
        where tasks.appeal_id = appeals.id AND tasks.type = 'TimedHoldTask'
        limit 1
      ) as timed_hold_task_status,
      (select tasks.id
        FROM tasks  AS tasks
        where tasks.appeal_id = appeals.id AND tasks.type IN ('AttorneyTask', 'AttorneyRewriteTask')
        limit 1
      ) as attorney_task_id,
      (select tasks.status
        FROM tasks  AS tasks
        where tasks.appeal_id = appeals.id AND tasks.type IN ('AttorneyTask', 'AttorneyRewriteTask')
        limit 1
      ) as attorney_task_status,
      (select tasks.started_at
        FROM tasks  AS tasks
        where tasks.appeal_id = appeals.id AND tasks.type IN ('AttorneyTask', 'AttorneyRewriteTask')
        limit 1
      ) as attorney_task_status_started_date,
      (select tasks.assigned_at
        FROM tasks  AS tasks
        where tasks.appeal_id = appeals.id AND tasks.type IN ('AttorneyTask', 'AttorneyRewriteTask')
        limit 1
      ) as attorney_task_status_assigned_date,
      (select tasks.status
        FROM tasks  AS tasks
        where tasks.appeal_id = appeals.id AND tasks.type = 'JudgeAssignTask'
        limit 1
      ) as judge_task_status,
      (select tasks.status
        FROM tasks  AS tasks
        where tasks.appeal_id = appeals.id AND tasks.type = 'JudgeAssignTask'
        limit 1
      ) as judge_assign_task_status,
      (select tasks.assigned_at
        FROM tasks  AS tasks
        where tasks.appeal_id = appeals.id AND tasks.type = 'JudgeAssignTask'
        limit 1
      ) as judge_assign_task_status_assigned_date,
      (select tasks.started_at
        FROM tasks  AS tasks
        where tasks.appeal_id = appeals.id AND tasks.type = 'JudgeAssignTask'
        limit 1
      ) as judge_assign_task_status_started_date,
      (select tasks.closed_at
        FROM tasks  AS tasks
        where tasks.appeal_id = appeals.id AND tasks.type = 'JudgeAssignTask'
        limit 1
      ) as judge_assign_task_status_completed_date,
      (select tasks.status
        FROM tasks  AS tasks
        where tasks.appeal_id = appeals.id AND tasks.type = 'JudgeDecisionReviewTask'
        limit 1
      ) as judge_decision_review_task_status,
      (select tasks.assigned_at
        FROM tasks  AS tasks
        where tasks.appeal_id = appeals.id AND tasks.type = 'JudgeDecisionReviewTask'
        limit 1
      ) as judge_decision_review_task_status_assigned_date,
      (select tasks.started_at
        FROM tasks  AS tasks
        where tasks.appeal_id = appeals.id AND tasks.type = 'JudgeDecisionReviewTask'
        limit 1
      ) as judge_decision_review_task_status_started_date,
      (select tasks.closed_at
        FROM tasks  AS tasks
        where tasks.appeal_id = appeals.id AND tasks.type = 'JudgeDecisionReviewTask'
        limit 1
      ) as judge_decision_review_task_status_completed_date,
      (select tasks.status
        FROM tasks  AS tasks
        where tasks.appeal_id = appeals.id AND tasks.type LIKE '%ColocatedTask%' AND tasks.appeal_type='Appeal'
        order by tasks.closed_at desc
        limit 1
      ) as colocated_task_status,
      (select tasks.status
        FROM tasks  AS tasks
        where tasks.appeal_id = appeals.id AND tasks.type = 'QualityReviewTask'
        limit 1
      ) as quality_review_task_status,
      (select users.id
        FROM tasks  AS tasks
        join users on tasks.assigned_to_id = users.id
        where tasks.appeal_id = appeals.id AND tasks.type IN ('AttorneyTask', 'AttorneyRewriteTask')
        limit 1
      ) as attorney_id,
      (select users.full_name
        FROM tasks  AS tasks
        join users on tasks.assigned_to_id = users.id
        where tasks.appeal_id = appeals.id AND tasks.type IN ('AttorneyTask', 'AttorneyRewriteTask')
        limit 1
      ) as attorney_name,
      (select cached_user_attributes.sattyid
        FROM tasks  AS tasks
        join users on tasks.assigned_to_id = users.id
        join cached_user_attributes on users.css_id = cached_user_attributes.sdomainid
        where tasks.appeal_id = appeals.id AND tasks.type IN ('AttorneyTask', 'AttorneyRewriteTask')
        limit 1
      ) as attorney_vacols_sattyid,
      (select cached_user_attributes.sattyid
        FROM tasks  AS tasks
        join users on tasks.assigned_to_id = users.id
        join cached_user_attributes on users.css_id = cached_user_attributes.sdomainid
        where tasks.appeal_id = appeals.id  AND tasks.type IN ('JudgeAssignTask', 'JudgeDecisionReviewTask')
        limit 1
      ) as judge_vacols_sattyid,
      (select users.id
        FROM tasks  AS tasks
        join users on tasks.assigned_to_id = users.id
        where tasks.appeal_id = appeals.id  AND tasks.type IN ('JudgeAssignTask', 'JudgeDecisionReviewTask')
        limit 1
      ) as judge_id,
      (select users.full_name
        FROM tasks  AS tasks
        join users on tasks.assigned_to_id = users.id
        where tasks.appeal_id = appeals.id  AND tasks.type IN ('JudgeAssignTask', 'JudgeDecisionReviewTask')
        limit 1
      ) as judge_name,
      (select tasks.status
        FROM tasks  AS tasks
        where tasks.appeal_id = appeals.id  AND tasks.type = 'BvaDispatchTask'
        limit 1
      ) as bva_dispatch_task_status,
      (select tasks.closed_at
        FROM tasks  AS tasks
        where tasks.appeal_id = appeals.id  AND tasks.type = 'BvaDispatchTask'
        limit 1
      ) as bva_dispatch_task_status_completed_date,
      (select tasks.status
        FROM tasks  AS tasks
        where tasks.appeal_id = appeals.id  AND tasks.type IN ('BvaDispatchTask', 'QualityReviewTask')
        limit 1
      ) as bva_dispatch_or_quality_review_task_status,
      (select tasks.status
        FROM tasks AS tasks
        WHERE tasks.appeal_id = appeals.id
        AND tasks.type IN (
          'JudgeQualityReviewTask',
          'JudgeDispatchReturnTask'
          'AttorneyQualityReviewTask',
          'AttorneyDispatchReturnTask'
        )
        limit 1
      ) as misc_task_status
      from public.appeals as appeals )
  SELECT to_char((DATE(appeal_task_status.receipt_date )), 'yymmdd') || '-' || appeal_task_status.id  AS "docket_number",
          appeal_task_status.*,
  CASE
    WHEN appeal_task_status.distribution_task_status IN ('on_hold', 'assigned', 'in_progress')
        AND (appeal_task_status.timed_hold_task_status IS NULL
             OR appeal_task_status.timed_hold_task_status NOT IN ('on_hold', 'assigned', 'in_progress')
        )
      THEN '1. Not distributed'
    WHEN appeal_task_status.judge_task_status IN ('assigned', 'in_progress')
      THEN '2. Distributed to judge'
    WHEN appeal_task_status.attorney_task_status = 'assigned'
      THEN '3. Assigned to attorney'
    WHEN appeal_task_status.colocated_task_status IN ('assigned', 'in_progress')
      THEN '4. Assigned to colocated'
    WHEN appeal_task_status.attorney_task_status = 'in_progress'
      THEN '5. Decision in progress'
    WHEN appeal_task_status.judge_decision_review_task_status IN ('assigned', 'in_progress')
      THEN '6. Decision ready for signature'
    WHEN appeal_task_status.bva_dispatch_or_quality_review_task_status IN ('assigned', 'in_progress')
      THEN '7. Decision signed'
    WHEN appeal_task_status.bva_dispatch_task_status = 'completed'
      AND appeal_task_status.root_task_status NOT IN ('on_hold', 'assigned', 'in_progress')
      THEN '8. Decision dispatched'
    WHEN appeal_task_status.timed_hold_task_status IN ('on_hold', 'assigned', 'in_progress')
      THEN 'ON HOLD'
    WHEN appeal_task_status.root_task_status = 'cancelled'
      THEN 'CANCELLED'
    WHEN appeal_task_status.misc_task_status IN ('assigned', 'in_progress')
      THEN 'MISC'
    ELSE 'UNKNOWN'
    END AS "appeal_task_status.decision_status",
  CASE
    WHEN appeal_task_status.judge_task_status is null  THEN '00'
    WHEN (appeal_task_status.judge_task_status = 'assigned' or appeal_task_status.judge_task_status = 'in_progress' or
          (appeal_task_status.colocated_task_status = 'assigned' or appeal_task_status.colocated_task_status = 'on_hold')) and appeal_task_status.attorney_task_status is null THEN '01'
    WHEN (appeal_task_status.judge_task_status = 'on_hold' or appeal_task_status.quality_review_task_status = 'on_hold') and appeal_task_status.attorney_task_status = 'assigned' THEN '02'
    WHEN (appeal_task_status.judge_task_status = 'on_hold' or appeal_task_status.attorney_task_status = 'on_hold') and appeal_task_status.colocated_task_status = 'assigned' or appeal_task_status.colocated_task_status = 'in_progress' THEN '03'
    WHEN (appeal_task_status.judge_task_status = 'on_hold' or appeal_task_status.quality_review_task_status = 'on_hold') and appeal_task_status.attorney_task_status = 'in_progress' THEN '04'
    WHEN (appeal_task_status.judge_task_status = 'assigned' or appeal_task_status.judge_task_status = 'in_progress') and appeal_task_status.attorney_task_status = 'completed' THEN '05'
    WHEN appeal_task_status.judge_task_status = 'completed' and appeal_task_status.attorney_task_status = 'completed' and (appeal_task_status.bva_dispatch_task_status is null or appeal_task_status.bva_dispatch_task_status != 'completed') THEN '06'
    WHEN appeal_task_status.judge_task_status = 'completed' and appeal_task_status.attorney_task_status = 'completed' and appeal_task_status.bva_dispatch_task_status = 'completed' THEN '07'
    WHEN appeal_task_status.judge_task_status = 'on_hold' and appeal_task_status.attorney_task_status = 'on_hold' and appeal_task_status.colocated_task_status = 'on_hold' THEN '08'
    WHEN appeal_task_status.judge_task_status = 'cancelled' or appeal_task_status.attorney_task_status = 'cancelled' THEN '09'
  END AS "appeal_task_status.decision_status__sort_",
    CASE WHEN appeal_task_status.judge_task_status = 'completed'  THEN 'Yes' ELSE 'No' END
   AS "appeal_task_status.decision_signed_by_judge",
    CASE WHEN appeal_task_status.attorney_task_status = 'completed'  THEN 'Yes' ELSE 'No' END
   AS "appeal_task_status.case_completed_by_attorney"
  FROM public.appeals  AS appeals
  LEFT JOIN appeal_task_status ON appeal_task_status.id = appeals.id

  WHERE
    (appeals.established_at  IS NOT NULL)
) "Appeals"
  LEFT JOIN "public"."users" "Judge" ON ("Appeals"."judge_id" = "Judge"."id")
  LEFT JOIN "public"."users" "Attorney" ON ("Appeals"."attorney_id" = "Attorney"."id")
  LEFT JOIN "public"."veterans" "Veteran" ON ("Appeals"."veteran_file_number" = CAST("Veteran"."file_number" AS TEXT))
  LEFT JOIN (
    WITH people_with_age AS (
      SELECT *, (DATE_PART('year', CURRENT_DATE) - DATE_PART('year', people.date_of_birth)) AS "veteran.age"
      FROM people
    )
  SELECT
     appeals.id  AS "appeals.id",
     advance_on_docket_motions.granted  AS "granted",
     advance_on_docket_motions.reason  AS "reason",
     "people_with_age"."veteran.age" AS "veteran.age",
     COALESCE(
       CASE "veteran.age" >= 75
       WHEN TRUE THEN TRUE
       ELSE advance_on_docket_motions.granted
       END, FALSE) AS "is_advanced_on_docket"
  FROM people_with_age
  LEFT JOIN public.claimants  AS claimants ON people_with_age.participant_id = claimants.participant_id
  LEFT JOIN public.advance_on_docket_motions  AS advance_on_docket_motions ON people_with_age.id = advance_on_docket_motions.person_id
  LEFT JOIN public.appeals  AS appeals ON claimants.decision_review_id = appeals.id AND claimants.decision_review_type = 'Appeal'
) "AOD Details" ON ("Appeals"."id" = "AOD Details"."appeals.id")
