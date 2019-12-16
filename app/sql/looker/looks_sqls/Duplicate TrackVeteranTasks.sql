SELECT 
	tasks.appeal_type  AS "tasks.appeal_type",
	tasks.appeal_id  AS "tasks.appeal_id",
	tasks.type  AS "tasks.type",
	tasks.assigned_to_type  AS "tasks.assigned_to_type",
	tasks.assigned_to_id  AS "tasks.assigned_to_id",
	tasks.action  AS "tasks.action"
FROM public.tasks  AS tasks

WHERE ((tasks.status  IN ('assigned', 'in_progress', 'on_hold'))) AND (tasks.assigned_to_type = 'Organization') AND (tasks.type = 'TrackVeteranTask')
GROUP BY 1,2,3,4,5,6
HAVING 
	(COUNT(DISTINCT tasks.id ) > 1)
ORDER BY 1 
LIMIT 500