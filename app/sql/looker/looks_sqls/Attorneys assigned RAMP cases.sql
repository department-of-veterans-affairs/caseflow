SELECT * FROM (
SELECT *, DENSE_RANK() OVER (ORDER BY z___min_rank) as z___pivot_row_rank, RANK() OVER (PARTITION BY z__pivot_col_rank ORDER BY z___min_rank) as z__pivot_col_ordering FROM (
SELECT *, MIN(z___rank) OVER (PARTITION BY "assigned_to_user.full_name") as z___min_rank FROM (
SELECT *, RANK() OVER (ORDER BY CASE WHEN z__pivot_col_rank=1 THEN 1 ELSE 2 END, CASE WHEN z__pivot_col_rank=1 THEN "tasks.count" ELSE NULL END DESC NULLS LAST, "tasks.count" DESC, z__pivot_col_rank, "assigned_to_user.full_name") AS z___rank FROM (
SELECT *, DENSE_RANK() OVER (ORDER BY "tasks.type" NULLS LAST, "tasks.status" NULLS LAST) AS z__pivot_col_rank FROM (
SELECT 
	tasks.type  AS "tasks.type",
	CASE tasks.status
          WHEN 'assigned' THEN '1_assigned'
          WHEN 'in_progress' THEN '2_viewed'
          WHEN 'on_hold' THEN '3_on_hold'
          WHEN 'completed' THEN '3_completed'
          ELSE tasks.status
         END
         AS "tasks.status",
	assigned_to_user.full_name  AS "assigned_to_user.full_name",
	COUNT(DISTINCT tasks.id ) AS "tasks.count"
FROM public.tasks  AS tasks
LEFT JOIN public.users  AS assigned_to_user ON tasks.assigned_to_type = 'User' AND tasks.assigned_to_id = assigned_to_user.id 

WHERE 
	(tasks.type = 'AttorneyTask')
GROUP BY 1,2,3) ww
) bb WHERE z__pivot_col_rank <= 16384
) aa
) xx
) zz
 WHERE z___pivot_row_rank <= 500 OR z__pivot_col_ordering = 1 ORDER BY z___pivot_row_rank

-- sql for creating the total and/or determining pivot columns
SELECT 
	tasks.type  AS "tasks.type",
	CASE tasks.status
          WHEN 'assigned' THEN '1_assigned'
          WHEN 'in_progress' THEN '2_viewed'
          WHEN 'on_hold' THEN '3_on_hold'
          WHEN 'completed' THEN '3_completed'
          ELSE tasks.status
         END
         AS "tasks.status",
	COUNT(DISTINCT tasks.id ) AS "tasks.count"
FROM public.tasks  AS tasks
LEFT JOIN public.users  AS assigned_to_user ON tasks.assigned_to_type = 'User' AND tasks.assigned_to_id = assigned_to_user.id 

WHERE 
	(tasks.type = 'AttorneyTask')
GROUP BY 1,2
ORDER BY 1 ,2 
LIMIT 500

-- sql for creating the pivot row totals
SELECT 
	assigned_to_user.full_name  AS "assigned_to_user.full_name",
	COUNT(DISTINCT tasks.id ) AS "tasks.count"
FROM public.tasks  AS tasks
LEFT JOIN public.users  AS assigned_to_user ON tasks.assigned_to_type = 'User' AND tasks.assigned_to_id = assigned_to_user.id 

WHERE 
	(tasks.type = 'AttorneyTask')
GROUP BY 1
ORDER BY 2 DESC
LIMIT 30000

-- sql for creating the grand totals
SELECT 
	COUNT(DISTINCT tasks.id ) AS "tasks.count"
FROM public.tasks  AS tasks
LEFT JOIN public.users  AS assigned_to_user ON tasks.assigned_to_type = 'User' AND tasks.assigned_to_id = assigned_to_user.id 

WHERE 
	(tasks.type = 'AttorneyTask')
LIMIT 1