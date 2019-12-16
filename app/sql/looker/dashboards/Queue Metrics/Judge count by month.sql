-- raw sql results do not include filled-in values for 'judge_case_reviews.created_month'


SELECT 
	TO_CHAR(DATE_TRUNC('month', judge_case_reviews.created_at ), 'YYYY-MM') AS "judge_case_reviews.created_month",
	COUNT(*) AS "judge_case_reviews.count",
	COUNT(DISTINCT users.id ) AS "users.count"
FROM public.judge_case_reviews  AS judge_case_reviews
LEFT JOIN public.users  AS users ON judge_case_reviews.judge_id = users.id 

GROUP BY DATE_TRUNC('month', judge_case_reviews.created_at )
ORDER BY 1 DESC
LIMIT 500