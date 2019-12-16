SELECT 
	appeals.id  AS "appeals.id",
	tasks.type  AS "tasks.type",
	CASE tasks.status
          WHEN 'assigned' THEN '1_assigned'
          WHEN 'in_progress' THEN '2_viewed'
          WHEN 'on_hold' THEN '3_on_hold'
          WHEN 'completed' THEN '3_completed'
          ELSE tasks.status
         END
         AS "tasks.status"
FROM public.appeals  AS appeals
LEFT JOIN public.tasks  AS tasks ON tasks.appeal_id = appeals.id AND tasks.appeal_type = 'Appeal' 

WHERE 
	(tasks.type  IN ('JudgeTask', 'AttorneyTask', 'BVADispatchTask'))
GROUP BY 1,2,3
ORDER BY 1 DESC,2 DESC
LIMIT 500