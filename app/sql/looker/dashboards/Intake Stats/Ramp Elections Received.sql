-- raw sql results do not include filled-in values for 'ramp_elections.receipt_month'


SELECT * FROM (
SELECT *, DENSE_RANK() OVER (ORDER BY z___min_rank) as z___pivot_row_rank, RANK() OVER (PARTITION BY z__pivot_col_rank ORDER BY z___min_rank) as z__pivot_col_ordering FROM (
SELECT *, MIN(z___rank) OVER (PARTITION BY "ramp_elections.receipt_month") as z___min_rank FROM (
SELECT *, RANK() OVER (ORDER BY "ramp_elections.receipt_month" ASC, z__pivot_col_rank) AS z___rank FROM (
SELECT *, DENSE_RANK() OVER (ORDER BY "ramp_elections.option_selected" NULLS LAST) AS z__pivot_col_rank FROM (
SELECT 
	ramp_elections.option_selected  AS "ramp_elections.option_selected",
	TO_CHAR(DATE_TRUNC('month', ramp_elections.receipt_date ), 'YYYY-MM') AS "ramp_elections.receipt_month",
	COUNT(*) AS "ramp_elections.count"
FROM public.ramp_elections  AS ramp_elections

WHERE 
	(ramp_elections.established_at  IS NOT NULL)
GROUP BY 1,DATE_TRUNC('month', ramp_elections.receipt_date )) ww
) bb WHERE z__pivot_col_rank <= 16384
) aa
) xx
) zz
 WHERE z___pivot_row_rank <= 500 OR z__pivot_col_ordering = 1 ORDER BY z___pivot_row_rank

-- sql for creating the pivot row totals
SELECT 
	TO_CHAR(DATE_TRUNC('month', ramp_elections.receipt_date ), 'YYYY-MM') AS "ramp_elections.receipt_month",
	COUNT(*) AS "ramp_elections.count"
FROM public.ramp_elections  AS ramp_elections

WHERE 
	(ramp_elections.established_at  IS NOT NULL)
GROUP BY DATE_TRUNC('month', ramp_elections.receipt_date )
ORDER BY 1 
LIMIT 30000