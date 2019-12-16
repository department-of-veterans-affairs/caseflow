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
SELECT *, MIN(z___rank) OVER (PARTITION BY "appeal_task_status.task_judge_name") as z___min_rank FROM (
SELECT *, RANK() OVER (ORDER BY CASE WHEN z__pivot_col_rank=1 THEN 1 ELSE 2 END, CASE WHEN z__pivot_col_rank=1 THEN "request_issues.count" ELSE NULL END DESC NULLS LAST, "request_issues.count" DESC, z__pivot_col_rank, "appeal_task_status.task_judge_name") AS z___rank FROM (
SELECT *, DENSE_RANK() OVER (ORDER BY "request_issues.disposition" NULLS LAST) AS z__pivot_col_rank FROM (
SELECT 
	request_issues.disposition  AS "request_issues.disposition",
	appeal_task_status.judge_name AS "appeal_task_status.task_judge_name",
	COUNT(request_issues.id ) AS "request_issues.count"
FROM public.appeals  AS appeals
LEFT JOIN public.request_issues  AS request_issues ON appeals.id = request_issues.decision_review_id 
LEFT JOIN appeal_task_status ON appeal_task_status.id = appeals.id 

WHERE (appeal_task_status.judge_task_status = 'completed')
GROUP BY 1,2) ww
) bb WHERE z__pivot_col_rank <= 16384
) aa
) xx
) zz
 WHERE z___pivot_row_rank <= 500 OR z__pivot_col_ordering = 1 ORDER BY z___pivot_row_rank