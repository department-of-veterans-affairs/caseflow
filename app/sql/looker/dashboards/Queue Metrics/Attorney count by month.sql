-- raw sql results do not include filled-in values for 'attorney_case_reviews.created_month'


SELECT 
	TO_CHAR(DATE_TRUNC('month', attorney_case_reviews.created_at ), 'YYYY-MM') AS "attorney_case_reviews.created_month",
	COUNT(*) AS "attorney_case_reviews.count",
	COUNT(DISTINCT attorneys.id ) AS "attorneys.count"
FROM public.attorney_case_reviews  AS attorney_case_reviews
LEFT JOIN public.users  AS attorneys ON attorney_case_reviews.attorney_id = attorneys.id 

GROUP BY DATE_TRUNC('month', attorney_case_reviews.created_at )
ORDER BY 1 DESC
LIMIT 500