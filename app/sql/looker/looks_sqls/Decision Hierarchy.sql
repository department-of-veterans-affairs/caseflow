SELECT 
	appeals.id  AS "appeals.id",
	coalesce(MAX((case when request_issues.disposition = 'allowed' then 3
            when request_issues.disposition = 'remanded' then 2
            when request_issues.disposition = 'denied' then 1
            end)), 0) AS "appeals.decision_hierarchy_max_points"
FROM public.appeals  AS appeals
LEFT JOIN public.request_issues  AS request_issues ON appeals.id = request_issues.decision_review_id 

WHERE 
	((request_issues.disposition IS NOT NULL))
GROUP BY 1
ORDER BY 1 
LIMIT 500