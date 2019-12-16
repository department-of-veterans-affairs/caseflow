SELECT 
	appeals.veteran_file_number  AS "appeals.veteran_file_number",
	appeals.docket_type  AS "appeals.docket_type",
	request_issues.disposition  AS "request_issues.disposition"
FROM public.tasks  AS tasks
LEFT JOIN public.appeals  AS appeals ON tasks.appeal_id = appeals.id AND tasks.appeal_type = 'Appeal'
LEFT JOIN public.request_issues  AS request_issues ON tasks.appeal_id = request_issues.decision_review_id

WHERE 
	(request_issues.disposition = 'stayed')
GROUP BY 1,2,3
ORDER BY 1 
LIMIT 500