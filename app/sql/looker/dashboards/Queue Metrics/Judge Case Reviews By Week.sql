-- raw sql results do not include filled-in values for 'judge_case_reviews.created_week'


SELECT 
	TO_CHAR(DATE_TRUNC('week', judge_case_reviews.created_at ), 'YYYY-MM-DD') AS "judge_case_reviews.created_week",
	COUNT(*) AS "judge_case_reviews.count"
FROM public.judge_case_reviews  AS judge_case_reviews

WHERE 
	(judge_case_reviews.created_at  < (DATEADD(week,0, DATE_TRUNC('week', DATE_TRUNC('day',GETDATE())) )))
GROUP BY DATE_TRUNC('week', judge_case_reviews.created_at )
ORDER BY 1 DESC
LIMIT 500