SELECT 
	appeals.veteran_file_number  AS "appeals.veteran_file_number",
	DATE(appeals.receipt_date ) AS "appeals.receipt_date",
	CASE tasks.status
          WHEN 'assigned' THEN '1_assigned'
          WHEN 'in_progress' THEN '2_viewed'
          WHEN 'on_hold' THEN '3_on_hold'
          WHEN 'completed' THEN '3_completed'
          ELSE tasks.status
         END
         AS "tasks.status",
	appeals.docket_type  AS "appeals.docket_type",
	request_issues.disposition  AS "request_issues.disposition",
	remand_reasons.code  AS "remand_reasons.code",
	COUNT(DISTINCT request_issues.id ) AS "request_issues.appeal_request_issue_count"
FROM public.tasks  AS tasks
LEFT JOIN public.appeals  AS appeals ON tasks.appeal_id = appeals.id AND tasks.appeal_type = 'Appeal'
LEFT JOIN public.request_issues  AS request_issues ON tasks.appeal_id = request_issues.decision_review_id
LEFT JOIN public.remand_reasons  AS remand_reasons ON request_issues.id = remand_reasons.request_issue_id

WHERE (tasks.type = 'QualityReviewTask') AND ((appeals.receipt_date  = DATE(DATE '2018-08-09') OR appeals.receipt_date  = DATE(DATE '2018-06-08') OR appeals.receipt_date  = DATE(DATE '2018-08-28') OR appeals.receipt_date  = DATE(DATE '2018-07-17') OR appeals.receipt_date  = DATE(DATE '2018-08-15')))
GROUP BY 1,2,3,4,5,6
ORDER BY 4 ,2 DESC
LIMIT 500