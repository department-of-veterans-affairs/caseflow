SELECT 
	dispatch_tasks.aasm_state  AS "dispatch_tasks.aasm_state",
	COUNT(*) AS "dispatch_tasks.count"
FROM public.dispatch_tasks  AS dispatch_tasks

GROUP BY 1
ORDER BY 2 DESC
LIMIT 500