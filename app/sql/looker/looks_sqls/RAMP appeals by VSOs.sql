SELECT * FROM (
SELECT *, DENSE_RANK() OVER (ORDER BY z___min_rank) as z___pivot_row_rank, RANK() OVER (PARTITION BY z__pivot_col_rank ORDER BY z___min_rank) as z__pivot_col_ordering FROM (
SELECT *, MIN(z___rank) OVER (PARTITION BY "assigned_to_organization.name") as z___min_rank FROM (
SELECT *, RANK() OVER (ORDER BY CASE WHEN z__pivot_col_rank=1 THEN 1 ELSE 2 END, CASE WHEN z__pivot_col_rank=1 THEN "appeals.count" ELSE NULL END DESC NULLS LAST, "appeals.count" DESC, z__pivot_col_rank, "assigned_to_organization.name") AS z___rank FROM (
SELECT *, DENSE_RANK() OVER (ORDER BY "appeals.docket_type" NULLS LAST) AS z__pivot_col_rank FROM (
SELECT 
	appeals.docket_type  AS "appeals.docket_type",
	assigned_to_organization.name  AS "assigned_to_organization.name",
	COUNT(DISTINCT appeals.id ) AS "appeals.count"
FROM public.tasks  AS tasks
LEFT JOIN public.appeals  AS appeals ON tasks.appeal_id = appeals.id AND tasks.appeal_type = 'Appeal'
LEFT JOIN public.organizations  AS assigned_to_organization ON tasks.assigned_to_type IN ('Organization', 'Vso') AND tasks.assigned_to_id = assigned_to_organization.id 

WHERE (tasks.type = 'TrackVeteranTask') AND ((((appeals.established_at ) >= (TIMESTAMP '2018-10-01') AND (appeals.established_at ) < (TIMESTAMP '2019-02-19'))))
GROUP BY 1,2) ww
) bb WHERE z__pivot_col_rank <= 16384
) aa
) xx
) zz
 WHERE z___pivot_row_rank <= 500 OR z__pivot_col_ordering = 1 ORDER BY z___pivot_row_rank

-- sql for creating the total and/or determining pivot columns
SELECT 
	appeals.docket_type  AS "appeals.docket_type",
	COUNT(DISTINCT appeals.id ) AS "appeals.count"
FROM public.tasks  AS tasks
LEFT JOIN public.appeals  AS appeals ON tasks.appeal_id = appeals.id AND tasks.appeal_type = 'Appeal'
LEFT JOIN public.organizations  AS assigned_to_organization ON tasks.assigned_to_type IN ('Organization', 'Vso') AND tasks.assigned_to_id = assigned_to_organization.id 

WHERE (tasks.type = 'TrackVeteranTask') AND ((((appeals.established_at ) >= (TIMESTAMP '2018-10-01') AND (appeals.established_at ) < (TIMESTAMP '2019-02-19'))))
GROUP BY 1
ORDER BY 1 
LIMIT 500

-- sql for creating the pivot row totals
SELECT 
	assigned_to_organization.name  AS "assigned_to_organization.name",
	COUNT(DISTINCT appeals.id ) AS "appeals.count"
FROM public.tasks  AS tasks
LEFT JOIN public.appeals  AS appeals ON tasks.appeal_id = appeals.id AND tasks.appeal_type = 'Appeal'
LEFT JOIN public.organizations  AS assigned_to_organization ON tasks.assigned_to_type IN ('Organization', 'Vso') AND tasks.assigned_to_id = assigned_to_organization.id 

WHERE (tasks.type = 'TrackVeteranTask') AND ((((appeals.established_at ) >= (TIMESTAMP '2018-10-01') AND (appeals.established_at ) < (TIMESTAMP '2019-02-19'))))
GROUP BY 1
ORDER BY 2 DESC
LIMIT 30000

-- sql for creating the grand totals
SELECT 
	COUNT(DISTINCT appeals.id ) AS "appeals.count"
FROM public.tasks  AS tasks
LEFT JOIN public.appeals  AS appeals ON tasks.appeal_id = appeals.id AND tasks.appeal_type = 'Appeal'
LEFT JOIN public.organizations  AS assigned_to_organization ON tasks.assigned_to_type IN ('Organization', 'Vso') AND tasks.assigned_to_id = assigned_to_organization.id 

WHERE (tasks.type = 'TrackVeteranTask') AND ((((appeals.established_at ) >= (TIMESTAMP '2018-10-01') AND (appeals.established_at ) < (TIMESTAMP '2019-02-19'))))
LIMIT 1