SELECT 
	assigned_to_user.full_name  AS "assigned_to_user.full_name",
	appeals.veteran_file_number  AS "appeals.veteran_file_number",
	DATE(tasks.assigned_at ) AS "tasks.assigned_date"
FROM public.tasks  AS tasks
LEFT JOIN public.appeals  AS appeals ON tasks.appeal_id = appeals.id AND tasks.appeal_type = 'Appeal'
LEFT JOIN public.users  AS assigned_to_user ON tasks.assigned_to_type = 'User' AND tasks.assigned_to_id = assigned_to_user.id 

WHERE ((CASE tasks.status
          WHEN 'assigned' THEN '1_assigned'
          WHEN 'in_progress' THEN '2_viewed'
          WHEN 'on_hold' THEN '3_on_hold'
          WHEN 'completed' THEN '3_completed'
          ELSE tasks.status
         END
         NOT IN ('3_completed', '3_on_hold') OR (CASE tasks.status
          WHEN 'assigned' THEN '1_assigned'
          WHEN 'in_progress' THEN '2_viewed'
          WHEN 'on_hold' THEN '3_on_hold'
          WHEN 'completed' THEN '3_completed'
          ELSE tasks.status
         END) IS NULL)) AND (tasks.type = 'JudgeAssignTask')
GROUP BY 1,2,3
ORDER BY 3 DESC
LIMIT 500