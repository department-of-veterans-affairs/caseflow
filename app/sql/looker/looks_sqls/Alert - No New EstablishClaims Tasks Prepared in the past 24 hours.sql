SELECT 
	TO_CHAR(dispatch_tasks.prepared_at , 'YYYY-MM-DD HH24:MI:SS') AS "dispatch_tasks.prepared_time",
	dispatch_tasks.appeal_id  AS "dispatch_tasks.appeal_id"
FROM public.dispatch_tasks  AS dispatch_tasks

WHERE 
	(((dispatch_tasks.prepared_at ) >= ((DATEADD(hour,-23, DATE_TRUNC('hour', GETDATE()) ))) AND (dispatch_tasks.prepared_at ) < ((DATEADD(hour,24, DATEADD(hour,-23, DATE_TRUNC('hour', GETDATE()) ) )))))
GROUP BY 1,2
ORDER BY 1 DESC
LIMIT 500