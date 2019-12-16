SELECT 
	appeals.veteran_file_number  AS "appeals.veteran_file_number",
	DATE(tasks.assigned_at ) AS "tasks.assigned_date",
	CASE tasks.assigned_to_type
          WHEN 'Organization' THEN assigned_to_organization.name
          WHEN 'User' THEN assigned_to_user.full_name
         END
         AS "tasks.completed_by"
FROM public.tasks  AS tasks
LEFT JOIN public.appeals  AS appeals ON tasks.appeal_id = appeals.id AND tasks.appeal_type = 'Appeal'
LEFT JOIN public.users  AS assigned_to_user ON tasks.assigned_to_type = 'User' AND tasks.assigned_to_id = assigned_to_user.id 
LEFT JOIN public.organizations  AS assigned_to_organization ON tasks.assigned_to_type IN ('Organization', 'Vso') AND tasks.assigned_to_id = assigned_to_organization.id 

WHERE (tasks.type = 'InformalHearingPresentationTask') AND ((CASE tasks.status
          WHEN 'assigned' THEN '1_assigned'
          WHEN 'in_progress' THEN '2_viewed'
          WHEN 'on_hold' THEN '3_on_hold'
          WHEN 'completed' THEN '3_completed'
          ELSE tasks.status
         END) = '3_completed')
GROUP BY 1,2,3
ORDER BY 2 DESC,3 
LIMIT 500