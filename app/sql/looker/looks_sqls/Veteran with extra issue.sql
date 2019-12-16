SELECT 
	appeals.id  AS "appeals.id",
	appeals.veteran_file_number  AS "appeals.veteran_file_number",
	COUNT(DISTINCT request_issues.id ) AS "request_issues.count"
FROM public.tasks  AS tasks
LEFT JOIN public.appeals  AS appeals ON tasks.appeal_id = appeals.id AND tasks.appeal_type = 'Appeal'
LEFT JOIN public.request_issues  AS request_issues ON tasks.appeal_id = request_issues.decision_review_id

WHERE 
	(appeals.veteran_file_number = '437515307')
GROUP BY 1,2
ORDER BY 1 
LIMIT 500