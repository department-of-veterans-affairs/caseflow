SELECT 
	appeals.id  AS "appeals.id",
	appeals.veteran_file_number  AS "appeals.veteran_file_number",
	tasks.id  AS "tasks.id",
	tasks.type  AS "tasks.type",
	CASE tasks.status
          WHEN 'assigned' THEN '1_assigned'
          WHEN 'in_progress' THEN '2_viewed'
          WHEN 'on_hold' THEN '3_on_hold'
          WHEN 'completed' THEN '3_completed'
          ELSE tasks.status
         END
         AS "tasks.status",
	DATE(tasks.created_at ) AS "tasks.created_date",
	DATE(tasks.assigned_at ) AS "tasks.assigned_date",
	DATE(tasks.started_at ) AS "tasks.started_date",
	DATE(tasks.updated_at ) AS "tasks.updated_date",
	task_assigned_to_organization.name  AS "task_assigned_to_organization.name",
	task_assigned_to_user.css_id  AS "task_assigned_to_user.css_id",
	task_assigned_by_user.css_id  AS "task_assigned_by_user.css_id"
FROM public.appeals  AS appeals
LEFT JOIN public.tasks  AS tasks ON tasks.appeal_id = appeals.id AND tasks.appeal_type = 'Appeal' 
LEFT JOIN public.users  AS task_assigned_to_user ON tasks.assigned_to_type = 'User' AND tasks.assigned_to_id = task_assigned_to_user.id 
LEFT JOIN public.users  AS task_assigned_by_user ON tasks.assigned_to_type = 'User' AND tasks.assigned_by_id = task_assigned_by_user.id 
LEFT JOIN public.organizations  AS task_assigned_to_organization ON tasks.assigned_to_type IN ('Organization', 'Vso') AND tasks.assigned_to_id = task_assigned_to_organization.id 

WHERE 
	(appeals.id  = 626)
GROUP BY 1,2,3,4,5,6,7,8,9,10,11,12
ORDER BY 7 
LIMIT 500