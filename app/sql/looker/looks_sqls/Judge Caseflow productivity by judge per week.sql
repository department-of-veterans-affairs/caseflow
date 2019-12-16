SELECT * FROM (
SELECT *, DENSE_RANK() OVER (ORDER BY z___min_rank) as z___pivot_row_rank, RANK() OVER (PARTITION BY z__pivot_col_rank ORDER BY z___min_rank) as z__pivot_col_ordering FROM (
SELECT *, MIN(z___rank) OVER (PARTITION BY "judge_case_reviews.judge_id","users.css_id","users.email","users.full_name") as z___min_rank FROM (
SELECT *, RANK() OVER (ORDER BY "judge_case_reviews.judge_id" ASC, z__pivot_col_rank, "users.css_id", "users.email", "users.full_name") AS z___rank FROM (
SELECT *, DENSE_RANK() OVER (ORDER BY "judge_case_reviews.created_week" NULLS LAST, "judge_case_reviews.is_legacy" NULLS LAST) AS z__pivot_col_rank FROM (
SELECT 
	TO_CHAR(DATE_TRUNC('week', judge_case_reviews.created_at ), 'YYYY-MM-DD') AS "judge_case_reviews.created_week",
	CASE WHEN strpos(judge_case_reviews.task_id, '-') > 0  THEN 'Yes' ELSE 'No' END
 AS "judge_case_reviews.is_legacy",
	judge_case_reviews.judge_id  AS "judge_case_reviews.judge_id",
	users.css_id  AS "users.css_id",
	users.email  AS "users.email",
	users.full_name  AS "users.full_name",
	COUNT(*) AS "judge_case_reviews.count"
FROM public.judge_case_reviews  AS judge_case_reviews
LEFT JOIN public.users  AS users ON judge_case_reviews.judge_id = users.id 

GROUP BY DATE_TRUNC('week', judge_case_reviews.created_at ),2,3,4,5,6) ww
) bb WHERE z__pivot_col_rank <= 16384
) aa
) xx
) zz
 WHERE z___pivot_row_rank <= 500 OR z__pivot_col_ordering = 1 ORDER BY z___pivot_row_rank

-- sql for creating the total and/or determining pivot columns
SELECT 
	TO_CHAR(DATE_TRUNC('week', judge_case_reviews.created_at ), 'YYYY-MM-DD') AS "judge_case_reviews.created_week",
	CASE WHEN strpos(judge_case_reviews.task_id, '-') > 0  THEN 'Yes' ELSE 'No' END
 AS "judge_case_reviews.is_legacy",
	COUNT(*) AS "judge_case_reviews.count"
FROM public.judge_case_reviews  AS judge_case_reviews
LEFT JOIN public.users  AS users ON judge_case_reviews.judge_id = users.id 

GROUP BY DATE_TRUNC('week', judge_case_reviews.created_at ),2
ORDER BY 1 ,2 
LIMIT 500

-- sql for creating the pivot row totals
SELECT 
	judge_case_reviews.judge_id  AS "judge_case_reviews.judge_id",
	users.css_id  AS "users.css_id",
	users.email  AS "users.email",
	users.full_name  AS "users.full_name",
	COUNT(*) AS "judge_case_reviews.count"
FROM public.judge_case_reviews  AS judge_case_reviews
LEFT JOIN public.users  AS users ON judge_case_reviews.judge_id = users.id 

GROUP BY 1,2,3,4
ORDER BY 1 
LIMIT 30000

-- sql for creating the grand totals
SELECT 
	COUNT(*) AS "judge_case_reviews.count"
FROM public.judge_case_reviews  AS judge_case_reviews
LEFT JOIN public.users  AS users ON judge_case_reviews.judge_id = users.id 

LIMIT 1