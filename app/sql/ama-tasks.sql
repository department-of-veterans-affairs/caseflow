SELECT
    "Tasks"."id" AS "id"
    ,"Tasks"."appeal_id" AS "appeal_id"
    ,CAST (
      "Tasks"."status" AS TEXT
    ) AS "status"
    ,CAST (
      "Tasks"."type" AS TEXT
    ) AS "type"
    ,CAST (
      "Tasks"."instructions" AS TEXT
    ) AS "instructions"
    ,"Tasks"."assigned_to_id" AS "assigned_to_id"
    ,"Tasks"."assigned_by_id" AS "assigned_by_id"
    ,"Tasks"."assigned_at" AS "assigned_at"
    ,"Tasks"."started_at" AS "started_at"
    ,"Tasks"."created_at" AS "created_at"
    ,"Tasks"."updated_at" AS "updated_at"
    ,CAST (
      "Tasks"."appeal_type" AS TEXT
    ) AS "appeal_type"
    ,"Tasks"."placed_on_hold_at" AS "placed_on_hold_at"
    ,CAST (
      "Tasks"."assigned_to_type" AS TEXT
    ) AS "assigned_to_type"
    ,"Tasks"."parent_id" AS "parent_id"
    ,"Tasks"."closed_at" AS "closed_at"
    ,"Assigned By User"."id" AS "id (users)"
    ,CAST (
      "Assigned By User"."station_id" AS TEXT
    ) AS "station_id"
    ,CAST (
      "Assigned By User"."css_id" AS TEXT
    ) AS "css_id"
    ,CAST (
      "Assigned By User"."full_name" AS TEXT
    ) AS "full_name"
    ,CAST (
      "Assigned By User"."email" AS TEXT
    ) AS "email"
    ,CAST (
      "Assigned By User"."roles" AS TEXT
    ) AS "roles"
    ,CAST (
      "Assigned By User"."selected_regional_office" AS TEXT
    ) AS "selected_regional_office"
    ,"Assigned By User"."last_login_at" AS "last_login_at"
    ,"Assigned By User"."created_at" AS "created_at (assigned by user)"
    ,"Assigned By User"."updated_at" AS "updated_at (assigned by user)"
    ,"Assigned By User"."efolder_documents_fetched_at" AS "efolder_documents_fetched_at"
    ,"Assigned To User"."id" AS "id (users) #1"
    ,CAST (
      "Assigned To User"."station_id" AS TEXT
    ) AS "station_id (users)"
    ,CAST (
      "Assigned To User"."css_id" AS TEXT
    ) AS "css_id (users)"
    ,CAST (
      "Assigned To User"."full_name" AS TEXT
    ) AS "full_name (users)"
    ,CAST (
      "Assigned To User"."email" AS TEXT
    ) AS "email (users)"
    ,CAST (
      "Assigned To User"."roles" AS TEXT
    ) AS "roles (users)"
    ,CAST (
      "Assigned To User"."selected_regional_office" AS TEXT
    ) AS "selected_regional_office (users)"
    ,"Assigned To User"."last_login_at" AS "last_login_at (assigned to user)"
    ,"Assigned To User"."created_at" AS "created_at (assigned to user)"
    ,"Assigned To User"."updated_at" AS "updated_at (assigned to user)"
    ,"Assigned To User"."efolder_documents_fetched_at" AS "efolder_documents_fetched_at (assigned to user)"
    ,CAST (
      "AMA Appeals"."docket_number" AS TEXT
    ) AS "docket_number"
    ,"AMA Appeals"."id" AS "id (custom sql query)"
    ,CAST (
      "AMA Appeals"."veteran_file_number" AS TEXT
    ) AS "veteran_file_number"
    ,"AMA Appeals"."receipt_date" AS "receipt_date"
    ,CAST (
      "AMA Appeals"."docket_type" AS TEXT
    ) AS "docket_type"
    ,"AMA Appeals"."established_at" AS "established_at"
    ,"AMA Appeals"."uuid" AS "uuid"
    ,"AMA Appeals"."legacy_opt_in_approved" AS "legacy_opt_in_approved"
    ,"AMA Appeals"."veteran_is_not_claimant" AS "veteran_is_not_claimant"
    ,"AMA Appeals"."establishment_submitted_at" AS "establishment_submitted_at"
    ,"AMA Appeals"."establishment_processed_at" AS "establishment_processed_at"
    ,"AMA Appeals"."establishment_attempted_at" AS "establishment_attempted_at"
    ,CAST (
      "AMA Appeals"."establishment_error" AS TEXT
    ) AS "establishment_error"
    ,"AMA Appeals"."establishment_last_submitted_at" AS "establishment_last_submitted_at"
    ,"AMA Appeals"."target_decision_date" AS "target_decision_date"
    ,CAST (
      "AMA Appeals"."closest_regional_office" AS TEXT
    ) AS "closest_regional_office (ama appeals)"
    ,"AMA Appeals"."establishment_canceled_at" AS "establishment_canceled_at"
    ,"AMA Appeals"."docket_range_date" AS "docket_range_date"
    ,CAST (
      "AMA Appeals"."poa_participant_id" AS TEXT
    ) AS "poa_participant_id"
    ,"AMA Appeals"."attorney_task_id" AS "attorney_task_id"
    ,CAST (
      "AMA Appeals"."distribution_task_status" AS TEXT
    ) AS "distribution_task_status"
    ,CAST (
      "AMA Appeals"."timed_hold_task_status" AS TEXT
    ) AS "timed_hold_task_status"
    ,CAST (
      "AMA Appeals"."judge_decision_review_task_status" AS TEXT
    ) AS "judge_decision_review_task_status"
    ,CAST (
      "AMA Appeals"."attorney_task_status" AS TEXT
    ) AS "attorney_task_status"
    ,"AMA Appeals"."attorney_task_status_started_date" AS "attorney_task_status_started_date"
    ,CAST (
      "AMA Appeals"."judge_task_status" AS TEXT
    ) AS "judge_task_status"
    ,CAST (
      "AMA Appeals"."quality_review_task_status" AS TEXT
    ) AS "quality_review_task_status"
    ,CAST (
      "AMA Appeals"."attorney_name" AS TEXT
    ) AS "attorney_name"
    ,"AMA Appeals"."attorney_id" AS "attorney_id"
    ,"AMA Appeals"."judge_id" AS "judge_id"
    ,CAST (
      "AMA Appeals"."judge_name" AS TEXT
    ) AS "judge_name"
    ,CAST (
      "AMA Appeals"."bva_dispatch_task_status" AS TEXT
    ) AS "bva_dispatch_task_status"
    ,"AMA Appeals"."bva_dispatch_task_status_completed_date" AS "bva_dispatch_task_status_completed_date"
    ,"AMA Appeals"."appeal_task_status.decision_status" AS "appeal_task_status.decision_status"
    ,"AMA Appeals"."appeal_task_status.decision_status__sort_" AS "appeal_task_status.decision_status__sort_"
    ,"AMA Appeals"."appeal_task_status.decision_signed_by_judge" AS "appeal_task_status.decision_signed_by_judge"
    ,"AMA Appeals"."appeal_task_status.case_completed_by_attorney" AS "appeal_task_status.case_completed_by_attorney"
    ,AOD.granted AS aod_granted
    ,"Veterans"."id" AS "id (veterans)"
    ,CAST (
      "Veterans"."file_number" AS TEXT
    ) AS "file_number"
    ,CAST (
      "Veterans"."participant_id" AS TEXT
    ) AS "participant_id"
    ,CAST (
      "Veterans"."first_name" AS TEXT
    ) AS "first_name"
    ,CAST (
      "Veterans"."last_name" AS TEXT
    ) AS "last_name"
    ,CAST (
      "Veterans"."middle_name" AS TEXT
    ) AS "middle_name"
    ,CAST (
      "Veterans"."name_suffix" AS TEXT
    ) AS "name_suffix"
    ,CAST (
      "Veterans"."closest_regional_office" AS TEXT
    ) AS "closest_regional_office"
    ,"Attorney"."id" AS "id (users) #2"
    ,CAST (
      "Attorney"."station_id" AS TEXT
    ) AS "station_id (users) #1"
    ,CAST (
      "Attorney"."css_id" AS TEXT
    ) AS "css_id (users) #1"
    ,CAST (
      "Attorney"."full_name" AS TEXT
    ) AS "full_name (users) #1"
    ,CAST (
      "Attorney"."email" AS TEXT
    ) AS "email (users) #1"
    ,CAST (
      "Attorney"."roles" AS TEXT
    ) AS "roles (users) #1"
    ,CAST (
      "Attorney"."selected_regional_office" AS TEXT
    ) AS "selected_regional_office (users) #1"
    ,"Attorney"."last_login_at" AS "last_login_at (attorney)"
    ,"Attorney"."created_at" AS "created_at (attorney)"
    ,"Attorney"."updated_at" AS "updated_at (attorney)"
    ,"Attorney"."efolder_documents_fetched_at" AS "efolder_documents_fetched_at (attorney)"
    ,"Judge"."id" AS "id (users) #3"
    ,CAST (
      "Judge"."station_id" AS TEXT
    ) AS "station_id (users) #2"
    ,CAST (
      "Judge"."css_id" AS TEXT
    ) AS "css_id (users) #2"
    ,CAST (
      "Judge"."full_name" AS TEXT
    ) AS "full_name (users) #2"
    ,CAST (
      "Judge"."email" AS TEXT
    ) AS "email (users) #2"
    ,CAST (
      "Judge"."roles" AS TEXT
    ) AS "roles (users) #2"
    ,CAST (
      "Judge"."selected_regional_office" AS TEXT
    ) AS "selected_regional_office (users) #2"
    ,"Judge"."last_login_at" AS "last_login_at (judge)"
    ,"Judge"."created_at" AS "created_at (judge)"
    ,"Judge"."updated_at" AS "updated_at (judge)"
    ,"Judge"."efolder_documents_fetched_at" AS "efolder_documents_fetched_at (judge)"
  FROM
    "public"."tasks" "Tasks" LEFT JOIN "public"."users" "Assigned By User"
      ON (
      "Tasks"."assigned_by_id" = "Assigned By User"."id"
    ) LEFT JOIN "public"."users" "Assigned To User"
      ON (
      "Tasks"."assigned_to_id" = "Assigned To User"."id"
    ) LEFT JOIN (
      WITH appeal_task_status AS (
        SELECT
            *
            ,(
              SELECT
                  tasks.status
                FROM
                  tasks AS tasks
                WHERE
                  tasks.appeal_id = appeals.id
                  AND tasks.type = 'RootTask' LIMIT 1
            ) AS root_task_status
            ,(
              SELECT
                  tasks.status
                FROM
                  tasks AS tasks
                WHERE
                  tasks.appeal_id = appeals.id
                  AND tasks.type = 'DistributionTask' LIMIT 1
            ) AS distribution_task_status
            ,(
              SELECT
                  tasks.status
                FROM
                  tasks AS tasks
                WHERE
                  tasks.appeal_id = appeals.id
                  AND tasks.type = 'TimedHoldTask' LIMIT 1
            ) AS timed_hold_task_status
            ,(
              SELECT
                  tasks.status
                FROM
                  tasks AS tasks
                WHERE
                  tasks.appeal_id = appeals.id
                  AND tasks.type = 'JudgeDecisionReviewTask' LIMIT 1
            ) AS judge_decision_review_task_status
            ,(
              SELECT
                  tasks.id
                FROM
                  tasks AS tasks
                WHERE
                  tasks.appeal_id = appeals.id
                  AND tasks.type IN (
                    'AttorneyTask'
                    ,'AttorneyRewriteTask'
                  ) LIMIT 1
            ) AS attorney_task_id
            ,(
              SELECT
                  tasks.STATUS
                FROM
                  tasks AS tasks
                WHERE
                  tasks.appeal_id = appeals.id
                  AND tasks.type IN (
                    'AttorneyTask'
                    ,'AttorneyRewriteTask'
                  ) LIMIT 1
            ) AS attorney_task_status
            ,(
              SELECT
                  tasks.started_at
                FROM
                  tasks AS tasks
                WHERE
                  tasks.appeal_id = appeals.id
                  AND tasks.type IN (
                    'AttorneyTask'
                    ,'AttorneyRewriteTask'
                  ) LIMIT 1
            ) AS attorney_task_status_started_date
            ,(
              SELECT
                  tasks.STATUS
                FROM
                  tasks AS tasks
                WHERE
                  tasks.appeal_id = appeals.id
                  AND tasks.type IN ('JudgeAssignTask') LIMIT 1
            ) AS judge_task_status
            ,(
              SELECT
                  tasks.STATUS
                FROM
                  tasks AS tasks
                WHERE
                  tasks.appeal_id = appeals.id
                  AND tasks.type LIKE '%ColocatedTask%'
                ORDER BY
                  tasks.closed_at DESC LIMIT 1
            ) AS colocated_task_status
            ,(
              SELECT
                  tasks.STATUS
                FROM
                  tasks AS tasks
                WHERE
                  tasks.appeal_id = appeals.id
                  AND tasks.type = 'QualityReviewTask' LIMIT 1
            ) AS quality_review_task_status
            ,(
              SELECT
                  users.full_name
                FROM
                  tasks AS tasks JOIN users
                    ON tasks.assigned_to_id = users.id
                WHERE
                  tasks.appeal_id = appeals.id
                  AND tasks.type = 'AttorneyTask' LIMIT 1
            ) AS attorney_name
            ,(
              SELECT
                  cached_user_attributes.sattyid
                FROM
                  tasks AS tasks JOIN users
                    ON tasks.assigned_to_id = users.id JOIN cached_user_attributes
                    ON users.css_id = cached_user_attributes.sdomainid
                WHERE
                  tasks.appeal_id = appeals.id
                  AND tasks.type = 'AttorneyTask' LIMIT 1
            ) AS attorney_id
            ,(
              SELECT
                  cached_user_attributes.sattyid
                FROM
                  tasks AS tasks JOIN users
                    ON tasks.assigned_to_id = users.id JOIN cached_user_attributes
                    ON users.css_id = cached_user_attributes.sdomainid
                WHERE
                  tasks.appeal_id = appeals.id
                  AND tasks.type IN (
                    'JudgeAssignTask'
                    ,'JudgeDecisionReviewTask'
                  ) LIMIT 1
            ) AS judge_id
            ,(
              SELECT
                  users.full_name
                FROM
                  tasks AS tasks JOIN users
                    ON tasks.assigned_to_id = users.id
                WHERE
                  tasks.appeal_id = appeals.id
                  AND tasks.type IN (
                    'JudgeAssignTask'
                    ,'JudgeDecisionReviewTask'
                  ) LIMIT 1
            ) AS judge_name
            ,(
              SELECT
                  tasks.STATUS
                FROM
                  tasks AS tasks
                WHERE
                  tasks.appeal_id = appeals.id
                  AND tasks.type = 'BvaDispatchTask' LIMIT 1
            ) AS bva_dispatch_task_status
            ,(
              SELECT
                  tasks.STATUS
                FROM
                  tasks AS tasks
                WHERE
                  tasks.appeal_id = appeals.id
                  AND tasks.type IN (
                    'BvaDispatchTask'
                    ,'QualityReviewTask'
                  ) LIMIT 1
            ) AS bva_dispatch_or_quality_review_task_status
            ,(
              SELECT
                  tasks.status
              FROM
                  tasks AS tasks
              WHERE
                  tasks.appeal_id = appeals.id
                  AND tasks.type IN (
                    'BoardGrantEffectuationTask'
                  ) LIMIT 1
            ) AS post_dispatch_task_status
            ,(
              SELECT
                  tasks.STATUS
                FROM
                  tasks AS tasks
                WHERE
                  tasks.appeal_id = appeals.id
                  AND tasks.type IN (
                    'JudgeQualityReviewTask'
                    ,'JudgeDispatchReturnTask'
                    ,'AttorneyQualityReviewTask'
                    ,'AttorneyDispatchReturnTask'
                  ) LIMIT 1
            ) AS misc_task_status
            ,(
              SELECT
                  tasks.closed_at
                FROM
                  tasks AS tasks
                WHERE
                  tasks.appeal_id = appeals.id
                  AND tasks.type = 'BvaDispatchTask' LIMIT 1
            ) AS bva_dispatch_task_status_completed_date
          FROM
            PUBLIC.appeals AS appeals
      ) SELECT
          to_char (
            (
              DATE( appeal_task_status.receipt_date )
            )
            ,'yymmdd'
          ) || '-' || appeal_task_status.id AS "docket_number"
          ,appeal_task_status. *
          ,CASE
            WHEN appeal_task_status.distribution_task_status IN (
              'on_hold'
              ,'assigned'
              ,'in_progress'
            )
            AND (
              appeal_task_status.timed_hold_task_status IS NULL
              OR appeal_task_status.timed_hold_task_status NOT IN (
                'on_hold'
                ,'assigned'
                ,'in_progress'
              )
            )
            THEN '1. Not distributed'
            WHEN appeal_task_status.judge_task_status IN (
              'assigned'
              ,'in_progress'
            )
            THEN '2. Distributed to judge'
            WHEN appeal_task_status.attorney_task_status = 'assigned'
            THEN '3. Assigned to attorney'
            WHEN appeal_task_status.colocated_task_status IN (
              'assigned'
              ,'in_progress'
            )
            THEN '4. Assigned to colocated'
            WHEN appeal_task_status.attorney_task_status = 'in_progress'
            THEN '5. Decision in progress'
            WHEN appeal_task_status.judge_decision_review_task_status IN (
              'assigned'
              ,'in_progress'
            )
            THEN '6. Decision ready for signature'
            WHEN appeal_task_status.bva_dispatch_or_quality_review_task_status IN (
              'assigned'
              ,'in_progress'
            )
            THEN '7. Decision signed'
            WHEN appeal_task_status.bva_dispatch_task_status = 'completed'
            AND appeal_task_status.root_task_status NOT IN (
              'on_hold'
              ,'assigned'
              ,'in_progress'
            )
            THEN '8. Decision dispatched'
            WHEN appeal_task_status.post_dispatch_task_status IN (
              'on_hold'
              ,'assigned'
              ,'in_progress'
            )
            THEN '9. Post dispatch tasks'
            WHEN appeal_task_status.timed_hold_task_status IN (
              'on_hold'
              ,'assigned'
              ,'in_progress'
            )
            THEN 'ON HOLD'
            WHEN appeal_task_status.root_task_status = 'cancelled'
            THEN 'CANCELLED'
            WHEN appeal_task_status.misc_task_status IN (
              'assigned'
              ,'in_progress'
            )
            THEN 'MISC'
          END AS "appeal_task_status.decision_status"
          ,CASE
            WHEN appeal_task_status.distribution_task_status IN (
              'on_hold'
              ,'assigned'
              ,'in_progress'
            )
            AND (
              appeal_task_status.timed_hold_task_status IS NULL
              OR appeal_task_status.timed_hold_task_status NOT IN (
                'on_hold'
                ,'assigned'
                ,'in_progress'
              )
            )
            THEN '00' -- '1. Not distributed'
            WHEN appeal_task_status.judge_task_status IN (
              'assigned'
              ,'in_progress'
            )
            THEN '01' -- '2. Distributed to judge'
            WHEN appeal_task_status.attorney_task_status = 'assigned'
            THEN '02' -- '3. Assigned to attorney'
            WHEN appeal_task_status.colocated_task_status IN (
              'assigned'
              ,'in_progress'
            )
            THEN '03' -- '4. Assigned to colocated'
            WHEN appeal_task_status.attorney_task_status = 'in_progress'
            THEN '04' -- '5. Decision in progress'
            WHEN appeal_task_status.judge_decision_review_task_status IN (
              'assigned'
              ,'in_progress'
            )
            THEN '05' -- '6. Decision ready for signature'
            WHEN appeal_task_status.bva_dispatch_or_quality_review_task_status IN (
              'assigned'
              ,'in_progress'
            )
            THEN '06' -- '7. Decision signed'
            WHEN appeal_task_status.bva_dispatch_task_status = 'completed'
            AND appeal_task_status.root_task_status NOT IN (
              'on_hold'
              ,'assigned'
              ,'in_progress'
            )
            THEN '07' -- '8. Decision dispatched'
            WHEN appeal_task_status.timed_hold_task_status IN (
              'on_hold'
              ,'assigned'
              ,'in_progress'
            )
            THEN '08' -- 'ON HOLD'
            WHEN appeal_task_status.root_task_status = 'cancelled'
            THEN '09' -- 'CANCELLED'
            WHEN appeal_task_status.misc_task_status IN (
              'assigned'
              ,'in_progress'
            )
            THEN '10' -- 'MISC'
            WHEN appeal_task_status.post_dispatch_task_status IN (
              'assigned'
              ,'in_progress'
              ,'on_hold'
            )
            THEN '12' -- '9. Post dispatch tasks'
            ELSE '11' -- 'UNKNOWN'
          END AS "appeal_task_status.decision_status__sort_"
          ,CASE
            WHEN appeal_task_status.judge_task_status = 'completed'
            THEN 'Yes'
            ELSE 'No'
          END AS "appeal_task_status.decision_signed_by_judge"
          ,CASE
            WHEN appeal_task_status.attorney_task_status = 'completed'
            THEN 'Yes'
            ELSE 'No'
          END AS "appeal_task_status.case_completed_by_attorney"
        FROM
          PUBLIC.appeals AS appeals LEFT JOIN appeal_task_status
            ON appeal_task_status.id = appeals.id
        WHERE
          (
            appeals.established_at IS NOT NULL
          )
    ) "AMA Appeals"
      ON (
      "Tasks"."appeal_id" = "AMA Appeals"."id"
    ) LEFT JOIN "public"."veterans" "Veterans"
      ON (
      "AMA Appeals"."veteran_file_number" = CAST (
        "Veterans"."file_number" AS TEXT
      )
    ) LEFT JOIN "public"."users" "Attorney"
      ON (
      "AMA Appeals"."attorney_id" = CAST (
        "Attorney"."id" AS TEXT
      )
    ) LEFT JOIN "public"."users" "Judge"
      ON (
      "AMA Appeals"."judge_id" = CAST (
        "Judge"."id" AS TEXT
      )
    ) LEFT JOIN claimants AS cl
      ON cl.decision_review_id = "AMA Appeals"."id"
    AND cl.decision_review_type = 'Appeal' LEFT JOIN people AS pe
      ON pe.participant_id = cl.participant_id LEFT JOIN advance_on_docket_motions AS aod
      ON aod.person_id = pe.id
