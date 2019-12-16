SELECT 
	appeals.veteran_file_number  AS "appeals.veteran_file_number",
	assigned_to_user.full_name  AS "assigned_to_user.full_name",
	assigned_to_user.css_id  AS "assigned_to_user.css_id",
	assigned_to_user.email  AS "assigned_to_user.email",
	COUNT(DISTINCT request_issues.id ) AS "request_issues.count"
FROM public.tasks  AS tasks
LEFT JOIN public.appeals  AS appeals ON tasks.appeal_id = appeals.id AND tasks.appeal_type = 'Appeal'
LEFT JOIN public.users  AS assigned_to_user ON tasks.assigned_to_type = 'User' AND tasks.assigned_to_id = assigned_to_user.id 
LEFT JOIN public.request_issues  AS request_issues ON tasks.appeal_id = request_issues.decision_review_id

WHERE (tasks.type = 'AttorneyTask') AND ((appeals.veteran_file_number  IN ('609228688', '250453306', '24611658', '29174023', '20805856')))
GROUP BY 1,2,3,4
ORDER BY 5 DESC
LIMIT 500