SELECT 
	appeals.veteran_file_number  AS "appeals.veteran_file_number",
	assigned_to_user.full_name  AS "assigned_to_user.full_name",
	CASE tasks.status
          WHEN 'assigned' THEN '1_assigned'
          WHEN 'in_progress' THEN '2_viewed'
          WHEN 'on_hold' THEN '3_on_hold'
          WHEN 'completed' THEN '3_completed'
          ELSE tasks.status
         END
         AS "tasks.status",
	DATE(decision_documents.decision_date ) AS "decision_documents.decision_date"
FROM public.tasks  AS tasks
LEFT JOIN public.appeals  AS appeals ON tasks.appeal_id = appeals.id AND tasks.appeal_type = 'Appeal'
LEFT JOIN public.users  AS assigned_to_user ON tasks.assigned_to_type = 'User' AND tasks.assigned_to_id = assigned_to_user.id 
LEFT JOIN public.decision_documents  AS decision_documents ON tasks.appeal_id = decision_documents.appeal_id

WHERE 
	(tasks.type = 'AttorneyTask')
GROUP BY 1,2,3,4
ORDER BY 4 DESC
LIMIT 500