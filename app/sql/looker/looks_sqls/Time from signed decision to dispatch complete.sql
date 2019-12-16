WITH appeal_task_status AS (SELECT *,
    (select max(tasks.updated_at)
            FROM tasks  AS tasks
            where tasks.appeal_id = appeals.id
            limit 1
          ) as task_max_updated_at,
          (select tasks.id
            FROM tasks  AS tasks
            where tasks.appeal_id = appeals.id AND tasks.type = 'AttorneyTask' AND tasks.appeal_type='Appeal'
            order by tasks.assigned_at desc
            limit 1
          ) as attorney_task_id,
          (select tasks.status
            FROM tasks  AS tasks
            where tasks.appeal_id = appeals.id  AND (tasks.type = 'AttorneyTask' or tasks.type = 'AttorneyRewriteTask') AND tasks.appeal_type='Appeal'
            order by tasks.assigned_at desc
            limit 1
          ) as attorney_task_status,
          (select tasks.started_at
            FROM tasks  AS tasks
            where tasks.appeal_id = appeals.id  AND (tasks.type = 'AttorneyTask' or tasks.type = 'AttorneyRewriteTask') AND tasks.appeal_type='Appeal'
            order by tasks.assigned_at desc
            limit 1
          ) as attorney_task_status_started_date,
          (select tasks.closed_at
            FROM tasks  AS tasks
            where tasks.appeal_id = appeals.id  AND (tasks.type = 'AttorneyTask' or tasks.type = 'AttorneyRewriteTask') AND tasks.appeal_type='Appeal'
            order by tasks.closed_at desc
            limit 1
          ) as attorney_task_status_completed_date,
          (select tasks.status
            FROM tasks  AS tasks
            where tasks.appeal_id = appeals.id  AND tasks.type = 'JudgeAssignTask' AND tasks.appeal_type='Appeal'
            limit 1
          ) as judge_assign_task_status,
          (select tasks.started_at
            FROM tasks  AS tasks
            where tasks.appeal_id = appeals.id  AND tasks.type = 'JudgeAssignTask' AND tasks.appeal_type='Appeal'
            limit 1
          ) as judge_assign_task_status_started_date,
          (select tasks.status
            FROM tasks  AS tasks
            where tasks.appeal_id = appeals.id  AND tasks.type = 'JudgeDecisionReviewTask' AND tasks.appeal_type='Appeal'
            limit 1
          ) as judge_review_task_status,
          (select tasks.started_at
            FROM tasks  AS tasks
            where tasks.appeal_id = appeals.id  AND tasks.type = 'JudgeDecisionReviewTask' AND tasks.appeal_type='Appeal'
            limit 1
          ) as judge_review_task_status_started_date,
          (select tasks.closed_at
            FROM tasks  AS tasks
            where tasks.appeal_id = appeals.id  AND tasks.type = 'JudgeDecisionReviewTask' AND tasks.appeal_type='Appeal'
            limit 1
          ) as judge_review_task_status_completed_date,
          (select tasks.status
            FROM tasks  AS tasks
              where tasks.appeal_id = appeals.id  AND tasks.type = 'ColocatedTask' AND tasks.appeal_type='Appeal'
            order by tasks.closed_at desc
            limit 1
          ) as colocated_task_status,
          (select tasks.status
            FROM tasks  AS tasks
            where tasks.appeal_id = appeals.id  AND tasks.type = 'QualityReviewTask' AND tasks.appeal_type='Appeal'
            order by tasks.assigned_at desc
            limit 1
          ) as quality_review_task_status,
          (select users.full_name
            FROM tasks  AS tasks
            join users on tasks.assigned_to_id = users.id
            where tasks.appeal_id = appeals.id  AND tasks.type = 'AttorneyTask' AND tasks.appeal_type='Appeal'
            order by tasks.assigned_at desc
            limit 1
          ) as attorney_name,
          (select vacols.staff.sattyid
            FROM tasks  AS tasks
            join users on tasks.assigned_to_id = users.id
            join vacols.staff on users.css_id = vacols.staff.sdomainid
            where tasks.appeal_id = appeals.id  AND tasks.type = 'AttorneyTask' AND tasks.appeal_type='Appeal'
            order by tasks.assigned_at desc
            limit 1
          ) as vacols_attorney_id,
          (select vacols.staff.sattyid
            FROM tasks  AS tasks
            join users on tasks.assigned_to_id = users.id
            join vacols.staff on users.css_id = vacols.staff.sdomainid
            where tasks.appeal_id = appeals.id  AND tasks.type IN ('JudgeAssignTask', 'JudgeDecisionReviewTask')  AND tasks.appeal_type='Appeal'
            order by tasks.assigned_at desc
            limit 1
          ) as vacols_judge_id,
          (select users.full_name
            FROM tasks  AS tasks
            join users on tasks.assigned_to_id = users.id
            where tasks.appeal_id = appeals.id  AND tasks.type IN ('JudgeAssignTask', 'JudgeDecisionReviewTask') AND tasks.appeal_type='Appeal'
            order by tasks.assigned_at desc
            limit 1
          ) as judge_name,
          (select tasks.status
            FROM tasks  AS tasks
            where tasks.appeal_id = appeals.id  AND tasks.type IN ('JudgeAssignTask', 'JudgeDecisionReviewTask') AND tasks.appeal_type='Appeal'
            order by tasks.assigned_at desc
            limit 1
          ) as judge_task_status,
          (select tasks.status
            FROM tasks  AS tasks
            where tasks.appeal_id = appeals.id  AND tasks.type = 'BvaDispatchTask' AND tasks.appeal_type='Appeal'
            limit 1
          ) as bva_dispatch_task_status,
          (select tasks.closed_at
            FROM tasks  AS tasks
            where tasks.appeal_id = appeals.id  AND tasks.type = 'BvaDispatchTask' AND tasks.appeal_type='Appeal'
            limit 1
          ) as bva_dispatch_task_status_completed_date
          from public.appeals as appeals )
SELECT 
	appeal_task_status.id  AS "appeal_task_status.appeal_id",
	(DATE(appeal_task_status.bva_dispatch_task_status_completed_date)) - (DATE(appeal_task_status.judge_review_task_status_completed_date)) AS "appeal_task_status.time_from_judge_signing_to_dispatch_complete",
	DATE(appeal_task_status.judge_review_task_status_completed_date) AS "appeal_task_status.judge_review_task_status_completed_at_date",
	DATE(appeal_task_status.bva_dispatch_task_status_completed_date) AS "appeal_task_status.bva_dispatch_task_status_completed_at_date"
FROM public.appeals  AS appeals
LEFT JOIN appeal_task_status ON appeal_task_status.id = appeals.id 

WHERE 
	(appeal_task_status.bva_dispatch_task_status_completed_date IS NOT NULL)
GROUP BY 1,2,3,4
ORDER BY 2 DESC
LIMIT 500