-- raw sql results do not include filled-in values for 'dispatch_tasks.completed_week'


SELECT 
	TO_CHAR(DATE_TRUNC('week', dispatch_tasks.completed_at ), 'YYYY-MM-DD') AS "dispatch_tasks.completed_week",
	COUNT(*) AS "dispatch_tasks.count"
FROM public.dispatch_tasks  AS dispatch_tasks

WHERE 
	(((dispatch_tasks.completed_at ) >= ((DATEADD(month,-8, DATE_TRUNC('month', DATE_TRUNC('day',GETDATE())) ))) AND (dispatch_tasks.completed_at ) < ((DATEADD(month,9, DATEADD(month,-8, DATE_TRUNC('month', DATE_TRUNC('day',GETDATE())) ) )))))
GROUP BY DATE_TRUNC('week', dispatch_tasks.completed_at )
ORDER BY 1 
LIMIT 500