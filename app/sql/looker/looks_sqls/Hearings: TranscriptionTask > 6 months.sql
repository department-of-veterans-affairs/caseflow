SELECT 
	DATE(tasks.started_at ) AS "tasks.started_date",
	tasks.type  AS "tasks.type",
	tasks.appeal_id  AS "tasks.appeal_id"
FROM public.tasks  AS tasks

WHERE ((tasks.started_at  < (DATEADD(month,-6, DATE_TRUNC('month', DATE_TRUNC('day',GETDATE())) )))) AND (((CASE tasks.status
          WHEN 'assigned' THEN '1_assigned'
          WHEN 'in_progress' THEN '2_viewed'
          WHEN 'on_hold' THEN '3_on_hold'
          WHEN 'completed' THEN '3_completed'
          ELSE tasks.status
         END) <> '3_completed' OR (CASE tasks.status
          WHEN 'assigned' THEN '1_assigned'
          WHEN 'in_progress' THEN '2_viewed'
          WHEN 'on_hold' THEN '3_on_hold'
          WHEN 'completed' THEN '3_completed'
          ELSE tasks.status
         END) IS NULL)) AND (tasks.type LIKE '%TranscriptionTask%')
GROUP BY 1,2,3
ORDER BY 1 DESC
LIMIT 500