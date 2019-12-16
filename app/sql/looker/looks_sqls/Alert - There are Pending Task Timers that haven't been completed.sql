SELECT 
	task_timers.id  AS "task_timers.id",
	DATE(task_timers.processed_at ) AS "task_timers.processed_date",
	DATE(task_timers.submitted_at ) AS "task_timers.submitted_date",
	DATE(task_timers.attempted_at ) AS "task_timers.attempted_date",
	DATE(task_timers.created_at ) AS "task_timers.created_date"
FROM public.appeals  AS appeals
LEFT JOIN public.tasks  AS tasks ON tasks.appeal_id = appeals.id AND tasks.appeal_type = 'Appeal' 
LEFT JOIN public.task_timers  AS task_timers ON task_timers.task_id =  tasks.id

WHERE ((task_timers.created_at  < (DATEADD(day,-1, DATE_TRUNC('day',GETDATE()) )))) AND (task_timers.processed_at  IS NULL) AND ((task_timers.submitted_at  < (DATEADD(day,-2, DATE_TRUNC('day',GETDATE()) ))))
GROUP BY 1,2,3,4,5
ORDER BY 2 DESC
LIMIT 500