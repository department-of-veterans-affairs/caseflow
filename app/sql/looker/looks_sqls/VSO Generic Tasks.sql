SELECT 
	appeals.veteran_file_number  AS "appeals.veteran_file_number",
	CASE tasks.status
          WHEN 'assigned' THEN '1_assigned'
          WHEN 'in_progress' THEN '2_viewed'
          WHEN 'on_hold' THEN '3_on_hold'
          WHEN 'completed' THEN '3_completed'
          ELSE tasks.status
         END
         AS "tasks.status",
	DATE(tasks.assigned_at ) AS "tasks.assigned_date"
FROM public.tasks  AS tasks
LEFT JOIN public.appeals  AS appeals ON tasks.appeal_id = appeals.id AND tasks.appeal_type = 'Appeal'

WHERE 
	(tasks.type = 'GenericTask')
GROUP BY 1,2,3
ORDER BY 2 DESC
LIMIT 500