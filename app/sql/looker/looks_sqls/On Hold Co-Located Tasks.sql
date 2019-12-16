SELECT 
	tasks.type  AS "tasks.type",
	tasks.instructions  AS "tasks.instructions",
	CASE tasks.status
          WHEN 'assigned' THEN '1_assigned'
          WHEN 'in_progress' THEN '2_viewed'
          WHEN 'on_hold' THEN '3_on_hold'
          WHEN 'completed' THEN '3_completed'
          ELSE tasks.status
         END
         AS "tasks.status",
	tasks.appeal_id  AS "tasks.appeal_id",
	appeals.veteran_file_number  AS "appeals.veteran_file_number",
	legacy_appeals.vbms_id  AS "legacy_appeals.vbms_id",
	COUNT(DISTINCT tasks.id ) AS "tasks.count"
FROM public.tasks  AS tasks
LEFT JOIN public.appeals  AS appeals ON tasks.appeal_id = appeals.id AND tasks.appeal_type = 'Appeal'
LEFT JOIN public.legacy_appeals  AS legacy_appeals ON tasks.appeal_id = legacy_appeals.id AND tasks.appeal_type = 'LegacyAppeal'

WHERE (((CASE tasks.status
          WHEN 'assigned' THEN '1_assigned'
          WHEN 'in_progress' THEN '2_viewed'
          WHEN 'on_hold' THEN '3_on_hold'
          WHEN 'completed' THEN '3_completed'
          ELSE tasks.status
         END) = '3_on_hold')) AND (tasks.type = 'ColocatedTask')
GROUP BY 1,2,3,4,5,6
ORDER BY 1 
LIMIT 100000