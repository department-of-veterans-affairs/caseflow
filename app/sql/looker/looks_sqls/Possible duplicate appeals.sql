SELECT * FROM (
SELECT *, DENSE_RANK() OVER (ORDER BY z___min_rank) as z___pivot_row_rank, RANK() OVER (PARTITION BY z__pivot_col_rank ORDER BY z___min_rank) as z__pivot_col_ordering FROM (
SELECT *, MIN(z___rank) OVER (PARTITION BY "appeals.veteran_file_number") as z___min_rank FROM (
SELECT *, RANK() OVER (ORDER BY CASE WHEN z__pivot_col_rank=1 THEN 1 ELSE 2 END, CASE WHEN z__pivot_col_rank=1 THEN "appeals.count" ELSE NULL END DESC NULLS LAST, "appeals.veteran_file_number" ASC, "appeals.count" DESC, z__pivot_col_rank) AS z___rank FROM (
SELECT *, DENSE_RANK() OVER (ORDER BY "appeals.docket_type" NULLS LAST) AS z__pivot_col_rank FROM (
SELECT 
	appeals.docket_type  AS "appeals.docket_type",
	appeals.veteran_file_number  AS "appeals.veteran_file_number",
	COUNT(*) AS "appeals.count"
FROM public.appeals  AS appeals

GROUP BY 1,2) ww
) bb WHERE z__pivot_col_rank <= 16384
) aa
) xx
) zz
 WHERE z___pivot_row_rank <= 500 OR z__pivot_col_ordering = 1 ORDER BY z___pivot_row_rank