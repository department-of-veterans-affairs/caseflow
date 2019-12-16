SELECT 
	appeals.veteran_file_number  AS "appeals.veteran_file_number",
	appeals.id  AS "appeals.id",
	assigned_to_user.css_id  AS "assigned_to_user.css_id",
	assigned_to_user.full_name  AS "assigned_to_user.full_name",
	tasks.type  AS "tasks.type",
	CASE tasks.status
          WHEN 'assigned' THEN '1_assigned'
          WHEN 'in_progress' THEN '2_viewed'
          WHEN 'on_hold' THEN '3_on_hold'
          WHEN 'completed' THEN '3_completed'
          ELSE tasks.status
         END
         AS "tasks.status"
FROM public.tasks  AS tasks
LEFT JOIN public.appeals  AS appeals ON tasks.appeal_id = appeals.id AND tasks.appeal_type = 'Appeal'
LEFT JOIN public.users  AS assigned_to_user ON tasks.assigned_to_type = 'User' AND tasks.assigned_to_id = assigned_to_user.id 

WHERE 
	(tasks.type = 'AttorneyTask')
GROUP BY 1,2,3,4,5,6
ORDER BY 1 DESC
LIMIT 750