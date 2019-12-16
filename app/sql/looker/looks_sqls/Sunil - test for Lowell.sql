SELECT 
	tasks.appeal_type  AS "tasks.appeal_type"
FROM public.tasks  AS tasks

WHERE 
	(tasks.assigned_to_type = 'Organization')
GROUP BY 1
ORDER BY 1 
LIMIT 500