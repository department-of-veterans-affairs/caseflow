WITH dispositions AS (WITH appeal_task_status AS (SELECT *,
          (select users.full_name
            FROM tasks  AS tasks
            join users on tasks.assigned_to_id = users.id
            where tasks.appeal_id = appeals.id  AND tasks.type = 'AttorneyTask'
            limit 1
          ) as attorney_name,
          (select tasks.status
            FROM tasks  AS tasks
            where tasks.appeal_id = appeals.id  AND tasks.type = 'JudgeTask'
            limit 1
          ) as judge_task_status,
          (select tasks.completed_at
            FROM tasks AS tasks
            where tasks.appeal_id = appeals.id  AND tasks.type = 'JudgeTask'
            limit 1
          ) as judge_task_completion,
          (select vacols.staff.sattyid
            FROM tasks  AS tasks
            join users on tasks.assigned_to_id = users.id
            join vacols.staff on users.css_id = vacols.staff.sdomainid
            where tasks.appeal_id = appeals.id  AND tasks.type = 'AttorneyTask'
            limit 1
          ) as attorney_id,
          (select vacols.staff.sattyid
            FROM tasks  AS tasks
            join users on tasks.assigned_to_id = users.id
            join vacols.staff on users.css_id = vacols.staff.sdomainid
            where tasks.appeal_id = appeals.id  AND tasks.type = 'JudgeTask'
            limit 1
          ) as judge_id,
          (select users.full_name
            FROM tasks  AS tasks
            join users on tasks.assigned_to_id = users.id
            where tasks.appeal_id = appeals.id  AND tasks.type = 'JudgeTask'
            limit 1
          ) as judge_name,
          (select vacols.staff.smemgrp
            FROM tasks  AS tasks
            join users on tasks.assigned_to_id = users.id
            join vacols.staff on users.css_id = vacols.staff.sdomainid
            where tasks.appeal_id = appeals.id  AND tasks.type = 'JudgeTask'
            limit 1
          ) as chief_group
          from public.appeals as appeals )
SELECT
  appeals.id  AS "appeals.id",
  appeal_task_status.judge_task_completion  AS "appeal_task_status.judge_task_completion",
  appeal_task_status.attorney_id AS "appeal_task_status.task_attorney_id",
  appeal_task_status.attorney_name AS "appeal_task_status.task_attorney_name",
  appeal_task_status.judge_id AS "appeal_task_status.task_judge_id",
  appeal_task_status.judge_name AS "appeal_task_status.task_judge_name",
  appeal_task_status.chief_group AS "appeal_task_status.chief_group",
  CASE WHEN decisions.citation_number IS NOT NULL   THEN 'Yes' ELSE 'No' END
 AS "decisions.bva_decision_dispatched",
  request_issues.id as "request_issues.id",
  request_issues.disposition as "request_issues.disposition"
FROM public.appeals AS appeals
LEFT JOIN public.request_issues  AS request_issues ON appeals.id = request_issues.review_request_id AND
    request_issues.review_request_type = 'Appeal'
LEFT JOIN public.decisions  AS decisions ON decisions.appeal_id = appeals.id
LEFT JOIN appeal_task_status ON appeal_task_status.id = appeals.id

WHERE appeal_task_status.judge_task_status = 'completed'

ORDER BY 2,1
LIMIT 500
 )
SELECT * FROM (
SELECT *, DENSE_RANK() OVER (ORDER BY z___min_rank) as z___pivot_row_rank, RANK() OVER (PARTITION BY z__pivot_col_rank ORDER BY z___min_rank) as z__pivot_col_ordering FROM (
SELECT *, MIN(z___rank) OVER (PARTITION BY "dispositions.appeal_task_status_task_judge_name","dispositions.appeal_task_status_task_attorney_name","dispositions.appeal_task_status_task_attorney_id") as z___min_rank FROM (
SELECT *, RANK() OVER (ORDER BY "dispositions.appeal_task_status_task_judge_name" DESC, z__pivot_col_rank, "dispositions.appeal_task_status_task_attorney_name", "dispositions.appeal_task_status_task_attorney_id") AS z___rank FROM (
SELECT *, DENSE_RANK() OVER (ORDER BY "dispositions.request_issues_disposition" NULLS LAST) AS z__pivot_col_rank FROM (
SELECT 
	dispositions."request_issues.disposition"  AS "dispositions.request_issues_disposition",
	dispositions."appeal_task_status.task_judge_name"  AS "dispositions.appeal_task_status_task_judge_name",
	dispositions."appeal_task_status.task_attorney_name"  AS "dispositions.appeal_task_status_task_attorney_name",
	dispositions."appeal_task_status.task_attorney_id"  AS "dispositions.appeal_task_status_task_attorney_id",
	COUNT(*) AS "dispositions.request_issues_disposition_count_per_attorney"
FROM dispositions

GROUP BY 1,2,3,4) ww
) bb WHERE z__pivot_col_rank <= 16384
) aa
) xx
) zz
 WHERE z___pivot_row_rank <= 500 OR z__pivot_col_ordering = 1 ORDER BY z___pivot_row_rank

-- sql for creating the total and/or determining pivot columns
WITH dispositions AS (WITH appeal_task_status AS (SELECT *,
          (select users.full_name
            FROM tasks  AS tasks
            join users on tasks.assigned_to_id = users.id
            where tasks.appeal_id = appeals.id  AND tasks.type = 'AttorneyTask'
            limit 1
          ) as attorney_name,
          (select tasks.status
            FROM tasks  AS tasks
            where tasks.appeal_id = appeals.id  AND tasks.type = 'JudgeTask'
            limit 1
          ) as judge_task_status,
          (select tasks.completed_at
            FROM tasks AS tasks
            where tasks.appeal_id = appeals.id  AND tasks.type = 'JudgeTask'
            limit 1
          ) as judge_task_completion,
          (select vacols.staff.sattyid
            FROM tasks  AS tasks
            join users on tasks.assigned_to_id = users.id
            join vacols.staff on users.css_id = vacols.staff.sdomainid
            where tasks.appeal_id = appeals.id  AND tasks.type = 'AttorneyTask'
            limit 1
          ) as attorney_id,
          (select vacols.staff.sattyid
            FROM tasks  AS tasks
            join users on tasks.assigned_to_id = users.id
            join vacols.staff on users.css_id = vacols.staff.sdomainid
            where tasks.appeal_id = appeals.id  AND tasks.type = 'JudgeTask'
            limit 1
          ) as judge_id,
          (select users.full_name
            FROM tasks  AS tasks
            join users on tasks.assigned_to_id = users.id
            where tasks.appeal_id = appeals.id  AND tasks.type = 'JudgeTask'
            limit 1
          ) as judge_name,
          (select vacols.staff.smemgrp
            FROM tasks  AS tasks
            join users on tasks.assigned_to_id = users.id
            join vacols.staff on users.css_id = vacols.staff.sdomainid
            where tasks.appeal_id = appeals.id  AND tasks.type = 'JudgeTask'
            limit 1
          ) as chief_group
          from public.appeals as appeals )
SELECT
  appeals.id  AS "appeals.id",
  appeal_task_status.judge_task_completion  AS "appeal_task_status.judge_task_completion",
  appeal_task_status.attorney_id AS "appeal_task_status.task_attorney_id",
  appeal_task_status.attorney_name AS "appeal_task_status.task_attorney_name",
  appeal_task_status.judge_id AS "appeal_task_status.task_judge_id",
  appeal_task_status.judge_name AS "appeal_task_status.task_judge_name",
  appeal_task_status.chief_group AS "appeal_task_status.chief_group",
  CASE WHEN decisions.citation_number IS NOT NULL   THEN 'Yes' ELSE 'No' END
 AS "decisions.bva_decision_dispatched",
  request_issues.id as "request_issues.id",
  request_issues.disposition as "request_issues.disposition"
FROM public.appeals AS appeals
LEFT JOIN public.request_issues  AS request_issues ON appeals.id = request_issues.review_request_id AND
    request_issues.review_request_type = 'Appeal'
LEFT JOIN public.decisions  AS decisions ON decisions.appeal_id = appeals.id
LEFT JOIN appeal_task_status ON appeal_task_status.id = appeals.id

WHERE appeal_task_status.judge_task_status = 'completed'

ORDER BY 2,1
LIMIT 500
 )
SELECT 
	dispositions."request_issues.disposition"  AS "dispositions.request_issues_disposition",
	COUNT(*) AS "dispositions.request_issues_disposition_count_per_attorney"
FROM dispositions

GROUP BY 1
ORDER BY 1 
LIMIT 500