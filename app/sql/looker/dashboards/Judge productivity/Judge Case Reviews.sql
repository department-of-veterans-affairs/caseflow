-- raw sql results do not include filled-in values for 'judge_case_reviews.created_week'


SELECT * FROM (
SELECT *, DENSE_RANK() OVER (ORDER BY z___min_rank) as z___pivot_row_rank, RANK() OVER (PARTITION BY z__pivot_col_rank ORDER BY z___min_rank) as z__pivot_col_ordering FROM (
SELECT *, MIN(z___rank) OVER (PARTITION BY "judge_case_reviews.judge_id") as z___min_rank FROM (
SELECT *, RANK() OVER (ORDER BY CASE WHEN z__pivot_col_rank=1 THEN 1 ELSE 2 END, CASE WHEN z__pivot_col_rank=1 THEN "judge_case_reviews.count" ELSE NULL END DESC NULLS LAST, "judge_case_reviews.count" DESC, z__pivot_col_rank, "judge_case_reviews.judge_id") AS z___rank FROM (
SELECT *, DENSE_RANK() OVER (ORDER BY "judge_case_reviews.created_week" NULLS LAST) AS z__pivot_col_rank FROM (
SELECT 
	TO_CHAR(DATE_TRUNC('week', judge_case_reviews.created_at ), 'YYYY-MM-DD') AS "judge_case_reviews.created_week",
	judge_case_reviews.judge_id  AS "judge_case_reviews.judge_id",
	COUNT(*) AS "judge_case_reviews.count"
FROM public.judge_case_reviews  AS judge_case_reviews

GROUP BY DATE_TRUNC('week', judge_case_reviews.created_at ),2) ww
) bb WHERE z__pivot_col_rank <= 16384
) aa
) xx
) zz
 WHERE z___pivot_row_rank <= 500 OR z__pivot_col_ordering = 1 ORDER BY z___pivot_row_rank