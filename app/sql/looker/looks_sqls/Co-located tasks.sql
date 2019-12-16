SELECT * FROM (
SELECT *, DENSE_RANK() OVER (ORDER BY z___min_rank) as z___pivot_row_rank, RANK() OVER (PARTITION BY z__pivot_col_rank ORDER BY z___min_rank) as z__pivot_col_ordering FROM (
SELECT *, MIN(z___rank) OVER (PARTITION BY "legacy_appeals.vbms_id","appeals.veteran_file_number","tasks.instructions","tasks.appeal_id","tasks.created_date","tasks.status","tasks.action") as z___min_rank FROM (
SELECT *, RANK() OVER (ORDER BY "tasks.created_date" DESC, z__pivot_col_rank, "legacy_appeals.vbms_id", "appeals.veteran_file_number", "tasks.instructions", "tasks.appeal_id", "tasks.status", "tasks.action") AS z___rank FROM (
SELECT *, DENSE_RANK() OVER (ORDER BY "tasks.assigned_to_id" DESC NULLS LAST) AS z__pivot_col_rank FROM (
SELECT 
	tasks.assigned_to_id  AS "tasks.assigned_to_id",
	legacy_appeals.vbms_id  AS "legacy_appeals.vbms_id",
	appeals.veteran_file_number  AS "appeals.veteran_file_number",
	tasks.instructions  AS "tasks.instructions",
	tasks.appeal_id  AS "tasks.appeal_id",
	DATE(tasks.created_at ) AS "tasks.created_date",
	CASE tasks.status
          WHEN 'assigned' THEN '1_assigned'
          WHEN 'in_progress' THEN '2_viewed'
          WHEN 'on_hold' THEN '3_on_hold'
          WHEN 'completed' THEN '3_completed'
          ELSE tasks.status
         END
         AS "tasks.status",
	tasks.action  AS "tasks.action",
	COUNT(DISTINCT tasks.id ) AS "tasks.count"
FROM public.tasks  AS tasks
LEFT JOIN public.appeals  AS appeals ON tasks.appeal_id = appeals.id AND tasks.appeal_type = 'Appeal'
LEFT JOIN public.legacy_appeals  AS legacy_appeals ON tasks.appeal_id = legacy_appeals.id AND tasks.appeal_type = 'LegacyAppeal'

WHERE 
	(tasks.type = 'ColocatedTask')
GROUP BY 1,2,3,4,5,6,7,8) ww
) bb WHERE z__pivot_col_rank <= 16384
) aa
) xx
) zz
 WHERE z___pivot_row_rank <= 500 OR z__pivot_col_ordering = 1 ORDER BY z___pivot_row_rank

-- sql for creating the total and/or determining pivot columns
SELECT 
	tasks.assigned_to_id  AS "tasks.assigned_to_id",
	COUNT(DISTINCT tasks.id ) AS "tasks.count"
FROM public.tasks  AS tasks
LEFT JOIN public.appeals  AS appeals ON tasks.appeal_id = appeals.id AND tasks.appeal_type = 'Appeal'
LEFT JOIN public.legacy_appeals  AS legacy_appeals ON tasks.appeal_id = legacy_appeals.id AND tasks.appeal_type = 'LegacyAppeal'

WHERE 
	(tasks.type = 'ColocatedTask')
GROUP BY 1
ORDER BY 1 DESC
LIMIT 500