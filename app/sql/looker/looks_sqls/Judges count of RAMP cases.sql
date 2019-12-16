SELECT * FROM (
SELECT *, DENSE_RANK() OVER (ORDER BY z___min_rank) as z___pivot_row_rank, RANK() OVER (PARTITION BY z__pivot_col_rank ORDER BY z___min_rank) as z__pivot_col_ordering FROM (
SELECT *, MIN(z___rank) OVER (PARTITION BY "assigned_to_user.full_name") as z___min_rank FROM (
SELECT *, RANK() OVER (ORDER BY CASE WHEN z__pivot_col_rank=1 THEN 1 ELSE 2 END, CASE WHEN z__pivot_col_rank=1 THEN "tasks.count" ELSE NULL END DESC NULLS LAST, "tasks.count" DESC, z__pivot_col_rank, "assigned_to_user.full_name") AS z___rank FROM (
SELECT *, DENSE_RANK() OVER (ORDER BY "tasks.type" NULLS LAST) AS z__pivot_col_rank FROM (
SELECT 
	tasks.type  AS "tasks.type",
	assigned_to_user.full_name  AS "assigned_to_user.full_name",
	COUNT(DISTINCT tasks.id ) AS "tasks.count"
FROM public.tasks  AS tasks
LEFT JOIN public.users  AS assigned_to_user ON tasks.assigned_to_type = 'User' AND tasks.assigned_to_id = assigned_to_user.id 

WHERE 
	(tasks.type  IN ('JudgeAssignTask', 'JudgeDecisionReviewTask'))
GROUP BY 1,2) ww
) bb WHERE z__pivot_col_rank <= 16384
) aa
) xx
) zz
 WHERE z___pivot_row_rank <= 500 OR z__pivot_col_ordering = 1 ORDER BY z___pivot_row_rank

-- sql for creating the total and/or determining pivot columns
SELECT 
	tasks.type  AS "tasks.type",
	COUNT(DISTINCT tasks.id ) AS "tasks.count"
FROM public.tasks  AS tasks
LEFT JOIN public.users  AS assigned_to_user ON tasks.assigned_to_type = 'User' AND tasks.assigned_to_id = assigned_to_user.id 

WHERE 
	(tasks.type  IN ('JudgeAssignTask', 'JudgeDecisionReviewTask'))
GROUP BY 1
ORDER BY 1 
LIMIT 500