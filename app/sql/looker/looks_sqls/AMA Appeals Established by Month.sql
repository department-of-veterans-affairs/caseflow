-- raw sql results do not include filled-in values for 'appeals.established_month'


SELECT * FROM (
SELECT *, DENSE_RANK() OVER (ORDER BY z___min_rank) as z___pivot_row_rank, RANK() OVER (PARTITION BY z__pivot_col_rank ORDER BY z___min_rank) as z__pivot_col_ordering FROM (
SELECT *, MIN(z___rank) OVER (PARTITION BY "appeals.docket_type") as z___min_rank FROM (
SELECT *, RANK() OVER (ORDER BY "appeals.docket_type" ASC, z__pivot_col_rank) AS z___rank FROM (
SELECT *, DENSE_RANK() OVER (ORDER BY "appeals.established_month" NULLS LAST) AS z__pivot_col_rank FROM (
SELECT 
	TO_CHAR(DATE_TRUNC('month', appeals.established_at ), 'YYYY-MM') AS "appeals.established_month",
	appeals.docket_type  AS "appeals.docket_type",
	COUNT(*) AS "appeals.count"
FROM public.appeals  AS appeals

WHERE 
	(appeals.established_at  IS NOT NULL)
GROUP BY DATE_TRUNC('month', appeals.established_at ),2) ww
) bb WHERE z__pivot_col_rank <= 16384
) aa
) xx
) zz
 WHERE z___pivot_row_rank <= 500 OR z__pivot_col_ordering = 1 ORDER BY z___pivot_row_rank

-- sql for creating the total and/or determining pivot columns
SELECT 
	TO_CHAR(DATE_TRUNC('month', appeals.established_at ), 'YYYY-MM') AS "appeals.established_month",
	COUNT(*) AS "appeals.count"
FROM public.appeals  AS appeals

WHERE 
	(appeals.established_at  IS NOT NULL)
GROUP BY DATE_TRUNC('month', appeals.established_at )
ORDER BY 1 
LIMIT 500

-- sql for creating the pivot row totals
SELECT 
	appeals.docket_type  AS "appeals.docket_type",
	COUNT(*) AS "appeals.count"
FROM public.appeals  AS appeals

WHERE 
	(appeals.established_at  IS NOT NULL)
GROUP BY 1
ORDER BY 1 
LIMIT 30000

-- sql for creating the grand totals
SELECT 
	COUNT(*) AS "appeals.count"
FROM public.appeals  AS appeals

WHERE 
	(appeals.established_at  IS NOT NULL)
LIMIT 1