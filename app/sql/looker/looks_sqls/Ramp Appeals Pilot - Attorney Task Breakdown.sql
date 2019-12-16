SELECT * FROM (
SELECT *, DENSE_RANK() OVER (ORDER BY z___min_rank) as z___pivot_row_rank, RANK() OVER (PARTITION BY z__pivot_col_rank ORDER BY z___min_rank) as z__pivot_col_ordering FROM (
SELECT *, MIN(z___rank) OVER (PARTITION BY "tasks.type","assigned_to_user.css_id","assigned_to_user.full_name","assigned_to_user.email","assigned_by_user.css_id","assigned_by_user.full_name") as z___min_rank FROM (
SELECT *, RANK() OVER (ORDER BY "tasks.type" ASC, z__pivot_col_rank, "assigned_to_user.css_id", "assigned_to_user.full_name", "assigned_to_user.email", "assigned_by_user.css_id", "assigned_by_user.full_name") AS z___rank FROM (
SELECT *, DENSE_RANK() OVER (ORDER BY "tasks.status" NULLS LAST) AS z__pivot_col_rank FROM (
SELECT 
	CASE tasks.status
          WHEN 'assigned' THEN '1_assigned'
          WHEN 'in_progress' THEN '2_viewed'
          WHEN 'on_hold' THEN '3_on_hold'
          WHEN 'completed' THEN '3_completed'
          ELSE tasks.status
         END
         AS "tasks.status",
	tasks.type  AS "tasks.type",
	assigned_to_user.css_id  AS "assigned_to_user.css_id",
	assigned_to_user.full_name  AS "assigned_to_user.full_name",
	assigned_to_user.email  AS "assigned_to_user.email",
	assigned_by_user.css_id  AS "assigned_by_user.css_id",
	assigned_by_user.full_name  AS "assigned_by_user.full_name",
	COUNT(DISTINCT tasks.id ) AS "tasks.count"
FROM public.tasks  AS tasks
LEFT JOIN public.users  AS assigned_to_user ON tasks.assigned_to_type = 'User' AND tasks.assigned_to_id = assigned_to_user.id 
LEFT JOIN public.users  AS assigned_by_user ON tasks.assigned_to_type = 'User' AND tasks.assigned_by_id = assigned_by_user.id 

WHERE 
	(tasks.type = 'AttorneyTask')
GROUP BY 1,2,3,4,5,6,7) ww
) bb WHERE z__pivot_col_rank <= 16384
) aa
) xx
) zz
 WHERE z___pivot_row_rank <= 500 OR z__pivot_col_ordering = 1 ORDER BY z___pivot_row_rank