WITH quota AS (SELECT
        (select tasks.completed_at
            FROM tasks AS tasks
            where tasks.appeal_id = appeals.id  AND tasks.type = 'JudgeTask'
            limit 1
        ) as date_signed,
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
        (select vacols.staff.smemgrp
            FROM tasks  AS tasks
            join users on tasks.assigned_to_id = users.id
            join vacols.staff on users.css_id = vacols.staff.sdomainid
            where tasks.appeal_id = appeals.id  AND tasks.type = 'JudgeTask'
            limit 1
        ) as chief_group,
        (select tasks.status
            FROM tasks  AS tasks
            where tasks.appeal_id = appeals.id  AND tasks.type = 'JudgeTask'
            limit 1
        ) as status,
        (select attorney_case_reviews.overtime
          FROM attorney_case_reviews
          INNER JOIN tasks on attorney_case_reviews.task_id = tasks.id
          WHERE tasks.appeal_id = appeals.id
          limit 1
        ) as overtime,
        appeals.id as id,
        request_issues.disposition as disposition
      FROM public.appeals as appeals
      LEFT JOIN public.request_issues  AS request_issues ON appeals.id = request_issues.review_request_id AND
        request_issues.review_request_type = 'Appeal'
      WHERE request_issues.disposition IS NOT NULL
ORDER BY 1,2
LIMIT 500
 )
SELECT * FROM (
SELECT *, DENSE_RANK() OVER (ORDER BY z___min_rank) as z___pivot_row_rank, RANK() OVER (PARTITION BY z__pivot_col_rank ORDER BY z___min_rank) as z__pivot_col_ordering FROM (
SELECT *, MIN(z___rank) OVER (PARTITION BY "quota.chief_group","quota.judge_id","quota.attorney_id","quota.date_signed_date") as z___min_rank FROM (
SELECT *, RANK() OVER (ORDER BY "quota.date_signed_date" DESC, z__pivot_col_rank, "quota.chief_group", "quota.judge_id", "quota.attorney_id") AS z___rank FROM (
SELECT *, DENSE_RANK() OVER (ORDER BY "quota.disposition" NULLS LAST) AS z__pivot_col_rank FROM (
SELECT 
	quota."disposition"  AS "quota.disposition",
	quota."chief_group"  AS "quota.chief_group",
	quota."judge_id"  AS "quota.judge_id",
	quota."attorney_id"  AS "quota.attorney_id",
	DATE(quota."date_signed" ) AS "quota.date_signed_date",
	COUNT(*) AS "quota.count"
FROM quota

WHERE (quota."date_signed"  IS NOT NULL) AND ((((quota."disposition") IS NOT NULL)))
GROUP BY 1,2,3,4,5) ww
) bb WHERE z__pivot_col_rank <= 16384
) aa
) xx
) zz
 WHERE z___pivot_row_rank <= 500 OR z__pivot_col_ordering = 1 ORDER BY z___pivot_row_rank