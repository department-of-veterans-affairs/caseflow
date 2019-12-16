-- raw sql results do not include filled-in values for 'intakes.completed_month'


SELECT * FROM (
SELECT *, DENSE_RANK() OVER (ORDER BY z___min_rank) as z___pivot_row_rank, RANK() OVER (PARTITION BY z__pivot_col_rank ORDER BY z___min_rank) as z__pivot_col_ordering FROM (
SELECT *, MIN(z___rank) OVER (PARTITION BY "intakes.completed_month") as z___min_rank FROM (
SELECT *, RANK() OVER (ORDER BY "intakes.completed_month" ASC, z__pivot_col_rank) AS z___rank FROM (
SELECT *, DENSE_RANK() OVER (ORDER BY "intakes.type" DESC NULLS LAST) AS z__pivot_col_rank FROM (
SELECT 
	intakes.type  AS "intakes.type",
	TO_CHAR(DATE_TRUNC('month', intakes.completed_at ), 'YYYY-MM') AS "intakes.completed_month",
	COUNT(*) AS "intakes.count"
FROM public.intakes  AS intakes

WHERE 
	(intakes.completion_status = 'success')
GROUP BY 1,DATE_TRUNC('month', intakes.completed_at )) ww
) bb WHERE z__pivot_col_rank <= 16384
) aa
) xx
) zz
 WHERE z___pivot_row_rank <= 500 OR z__pivot_col_ordering = 1 ORDER BY z___pivot_row_rank

-- sql for creating the pivot row totals
SELECT 
	TO_CHAR(DATE_TRUNC('month', intakes.completed_at ), 'YYYY-MM') AS "intakes.completed_month",
	COUNT(*) AS "intakes.count"
FROM public.intakes  AS intakes

WHERE 
	(intakes.completion_status = 'success')
GROUP BY DATE_TRUNC('month', intakes.completed_at )
ORDER BY 1 
LIMIT 30000