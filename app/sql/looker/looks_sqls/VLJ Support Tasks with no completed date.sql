SELECT 
	task_assigned_to_user.full_name  AS "task_assigned_to_user.full_name",
	tasks.action  AS "tasks.action",
	DATE(tasks.created_at ) AS "tasks.created_date",
	CASE tasks.status
          WHEN 'assigned' THEN '1_assigned'
          WHEN 'in_progress' THEN '2_viewed'
          WHEN 'on_hold' THEN '3_on_hold'
          WHEN 'completed' THEN '3_completed'
          ELSE tasks.status
         END
         AS "tasks.status",
	tasks.type  AS "tasks.type"
FROM public.appeals  AS appeals
LEFT JOIN public.tasks  AS tasks ON tasks.appeal_id = appeals.id AND tasks.appeal_type = 'Appeal' 
LEFT JOIN public.users  AS task_assigned_to_user ON tasks.assigned_to_type = 'User' AND tasks.assigned_to_id = task_assigned_to_user.id 

WHERE 
	(tasks.type = 'ColocatedTask')
GROUP BY 1,2,3,4,5
ORDER BY 3 DESC
LIMIT 1000