-- raw sql results do not include filled-in values for 'appeal_task_status.decision_status'


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
SELECT * FROM (
SELECT *, DENSE_RANK() OVER (ORDER BY z___min_rank) as z___pivot_row_rank, RANK() OVER (PARTITION BY z__pivot_col_rank ORDER BY z___min_rank) as z__pivot_col_ordering FROM (
SELECT *, MIN(z___rank) OVER (PARTITION BY "appeal_task_status.decision_status__sort_","appeal_task_status.decision_status") as z___min_rank FROM (
SELECT *, RANK() OVER (ORDER BY "appeal_task_status.decision_status__sort_" ASC, z__pivot_col_rank, "appeal_task_status.decision_status") AS z___rank FROM (
SELECT *, DENSE_RANK() OVER (ORDER BY "appeals.docket_type" NULLS LAST) AS z__pivot_col_rank FROM (
SELECT 
	appeals.docket_type  AS "appeals.docket_type",
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
	CASE
WHEN appeal_task_status.judge_task_status is null  THEN '1. Not distributed' 
WHEN (appeal_task_status.judge_task_status = 'assigned' or appeal_task_status.judge_task_status = 'in_progress' or
          (appeal_task_status.colocated_task_status = 'assigned' or appeal_task_status.colocated_task_status = 'on_hold')) and appeal_task_status.attorney_task_status is null THEN '2. Distributed to judge' 
WHEN (appeal_task_status.judge_task_status = 'on_hold' or appeal_task_status.quality_review_task_status = 'on_hold') and appeal_task_status.attorney_task_status = 'assigned' THEN '3. Assigned to attorney' 
WHEN (appeal_task_status.judge_task_status = 'on_hold' or appeal_task_status.attorney_task_status = 'on_hold') and appeal_task_status.colocated_task_status = 'assigned' or appeal_task_status.colocated_task_status = 'in_progress' THEN '4. Assigned to colocated' 
WHEN (appeal_task_status.judge_task_status = 'on_hold' or appeal_task_status.quality_review_task_status = 'on_hold') and appeal_task_status.attorney_task_status = 'in_progress' THEN '5. Decision in progress' 
WHEN (appeal_task_status.judge_task_status = 'assigned' or appeal_task_status.judge_task_status = 'in_progress') and appeal_task_status.attorney_task_status = 'completed' THEN '6. Decision ready for signature' 
WHEN appeal_task_status.judge_task_status = 'completed' and appeal_task_status.attorney_task_status = 'completed' and (appeal_task_status.bva_dispatch_task_status is null or appeal_task_status.bva_dispatch_task_status != 'completed') THEN '7. Decision signed' 
WHEN appeal_task_status.judge_task_status = 'completed' and appeal_task_status.attorney_task_status = 'completed' and appeal_task_status.bva_dispatch_task_status = 'completed' THEN '8. Decision dispatched' 
WHEN appeal_task_status.judge_task_status = 'on_hold' and appeal_task_status.attorney_task_status = 'on_hold' and appeal_task_status.colocated_task_status = 'on_hold' THEN 'ON HOLD' 
WHEN appeal_task_status.judge_task_status = 'cancelled' or appeal_task_status.attorney_task_status = 'cancelled' THEN 'CANCELLED' 
END AS "appeal_task_status.decision_status",
	COUNT(*) AS "appeals.count"
FROM public.appeals  AS appeals
LEFT JOIN appeal_task_status ON appeal_task_status.id = appeals.id 

WHERE 
	(appeals.established_at  IS NOT NULL)
GROUP BY 1,2,3) ww
) bb WHERE z__pivot_col_rank <= 16384
) aa
) xx
) zz
 WHERE z___pivot_row_rank <= 500 OR z__pivot_col_ordering = 1 ORDER BY z___pivot_row_rank

-- sql for creating the total and/or determining pivot columns
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
	appeals.docket_type  AS "appeals.docket_type",
	COUNT(*) AS "appeals.count"
FROM public.appeals  AS appeals
LEFT JOIN appeal_task_status ON appeal_task_status.id = appeals.id 

WHERE 
	(appeals.established_at  IS NOT NULL)
GROUP BY 1
ORDER BY 1 
LIMIT 500