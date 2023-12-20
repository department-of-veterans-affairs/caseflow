SELECT
	DATE(task_timers.created_at ) AS "task_timers.created_date",
	task_timers.id  AS "task_timers.id",
	DATE(task_timers.submitted_at ) AS "task_timers.submitted_date",
	DATE(task_timers.attempted_at ) AS "task_timers.attempted_date",
	task_timers.task_id  AS "task_timers.task_id"
FROM public.task_timers  AS task_timers

WHERE ((task_timers.created_at  < (DATEADD(day,-1, DATE_TRUNC('day',GETDATE()) )))) AND (task_timers.processed_at  IS NULL) AND (task_timers.canceled_at  IS NULL) AND ((task_timers.submitted_at  < (DATEADD(day,-2, DATE_TRUNC('day',GETDATE()) ))))
ORDER BY 1 DESC
LIMIT 500
