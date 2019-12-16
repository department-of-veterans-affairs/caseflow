SELECT 
	assigned_to_organization.name  AS "assigned_to_organization.name",
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
LEFT JOIN public.organizations  AS assigned_to_organization ON tasks.assigned_to_type IN ('Organization', 'Vso') AND tasks.assigned_to_id = assigned_to_organization.id 

WHERE 
	(tasks.type = 'InformalHearingPresentationTask')
GROUP BY 1,2,3,4
ORDER BY 3 DESC
LIMIT 500