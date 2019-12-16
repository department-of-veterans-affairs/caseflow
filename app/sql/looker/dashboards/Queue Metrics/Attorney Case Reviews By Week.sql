-- raw sql results do not include filled-in values for 'attorney_case_reviews.created_week'


SELECT * FROM (
SELECT *, DENSE_RANK() OVER (ORDER BY z___min_rank) as z___pivot_row_rank, RANK() OVER (PARTITION BY z__pivot_col_rank ORDER BY z___min_rank) as z__pivot_col_ordering FROM (
SELECT *, MIN(z___rank) OVER (PARTITION BY "attorney_case_reviews.created_week") as z___min_rank FROM (
SELECT *, RANK() OVER (ORDER BY "attorney_case_reviews.created_week" DESC, z__pivot_col_rank) AS z___rank FROM (
SELECT *, DENSE_RANK() OVER (ORDER BY "attorney_case_reviews.document_type" NULLS LAST) AS z__pivot_col_rank FROM (
SELECT 
	attorney_case_reviews.document_type  AS "attorney_case_reviews.document_type",
	TO_CHAR(DATE_TRUNC('week', attorney_case_reviews.created_at ), 'YYYY-MM-DD') AS "attorney_case_reviews.created_week",
	COUNT(*) AS "attorney_case_reviews.count"
FROM public.attorney_case_reviews  AS attorney_case_reviews

WHERE 
	(attorney_case_reviews.created_at  < (DATEADD(week,0, DATE_TRUNC('week', DATE_TRUNC('day',GETDATE())) )))
GROUP BY 1,DATE_TRUNC('week', attorney_case_reviews.created_at )) ww
) bb WHERE z__pivot_col_rank <= 16384
) aa
) xx
) zz
 WHERE z___pivot_row_rank <= 500 OR z__pivot_col_ordering = 1 ORDER BY z___pivot_row_rank