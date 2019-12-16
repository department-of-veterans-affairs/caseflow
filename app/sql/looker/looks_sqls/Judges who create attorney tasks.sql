SELECT 
	assigned_by_user.full_name  AS "assigned_by_user.full_name",
	COUNT(DISTINCT tasks.id ) AS "tasks.count"
FROM public.tasks  AS tasks
LEFT JOIN public.users  AS assigned_by_user ON tasks.assigned_to_type = 'User' AND tasks.assigned_by_id = assigned_by_user.id 

WHERE 
	(tasks.type = 'AttorneyTask')
GROUP BY 1
ORDER BY 2 DESC
LIMIT 500