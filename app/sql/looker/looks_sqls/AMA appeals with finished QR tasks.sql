SELECT * FROM (
SELECT *, DENSE_RANK() OVER (ORDER BY z___min_rank) as z___pivot_row_rank, RANK() OVER (PARTITION BY z__pivot_col_rank ORDER BY z___min_rank) as z__pivot_col_ordering FROM (
SELECT *, MIN(z___rank) OVER (PARTITION BY "appeals.veteran_file_number","appeals.receipt_date","assigned_to_user.css_id","tasks.status","appeals.docket_type") as z___min_rank FROM (
SELECT *, RANK() OVER (ORDER BY "appeals.docket_type" ASC, "appeals.receipt_date" DESC, z__pivot_col_rank, "appeals.veteran_file_number", "assigned_to_user.css_id", "tasks.status") AS z___rank FROM (
SELECT *, DENSE_RANK() OVER (ORDER BY "request_issues.disposition" NULLS LAST) AS z__pivot_col_rank FROM (
SELECT 
	request_issues.disposition  AS "request_issues.disposition",
	appeals.veteran_file_number  AS "appeals.veteran_file_number",
	DATE(appeals.receipt_date ) AS "appeals.receipt_date",
	assigned_to_user.css_id  AS "assigned_to_user.css_id",
	CASE tasks.status
          WHEN 'assigned' THEN '1_assigned'
          WHEN 'in_progress' THEN '2_viewed'
          WHEN 'on_hold' THEN '3_on_hold'
          WHEN 'completed' THEN '3_completed'
          ELSE tasks.status
         END
         AS "tasks.status",
	appeals.docket_type  AS "appeals.docket_type",
	COUNT(DISTINCT request_issues.id ) AS "request_issues.appeal_request_issue_count"
FROM public.tasks  AS tasks
LEFT JOIN public.appeals  AS appeals ON tasks.appeal_id = appeals.id AND tasks.appeal_type = 'Appeal'
LEFT JOIN public.users  AS assigned_to_user ON tasks.assigned_to_type = 'User' AND tasks.assigned_to_id = assigned_to_user.id 
LEFT JOIN public.request_issues  AS request_issues ON tasks.appeal_id = request_issues.decision_review_id

WHERE (tasks.type = 'BvaDispatchTask') AND ((appeals.receipt_date  = DATE(DATE '2018-08-09') OR appeals.receipt_date  = DATE(DATE '2018-06-08') OR appeals.receipt_date  = DATE(DATE '2018-08-28') OR appeals.receipt_date  = DATE(DATE '2018-07-17') OR appeals.receipt_date  = DATE(DATE '2018-08-15')))
GROUP BY 1,2,3,4,5,6) ww
) bb WHERE z__pivot_col_rank <= 16384
) aa
) xx
) zz
 WHERE z___pivot_row_rank <= 500 OR z__pivot_col_ordering = 1 ORDER BY z___pivot_row_rank