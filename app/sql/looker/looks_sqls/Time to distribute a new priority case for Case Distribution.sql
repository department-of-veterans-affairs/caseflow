SELECT 
	TO_CHAR(DATE_TRUNC('week', distributions.completed_at ), 'YYYY-MM-DD') AS "distributions.completed_week",
	AVG((DATEDIFF(days, DATE((DATE(distributed_cases.ready_at ))), (DATE(distributions.completed_at )))) ) AS "distributed_cases.average_priority_case_wait"
FROM public.distributions  AS distributions
LEFT JOIN public.distributed_cases  AS distributed_cases ON distributions.id = distributed_cases.distribution_id 

WHERE 
	(distributed_cases.priority = 'true')
GROUP BY DATE_TRUNC('week', distributions.completed_at )
HAVING 
	NOT (AVG((DATEDIFF(days, DATE((DATE(distributed_cases.ready_at ))), (DATE(distributions.completed_at )))) ) IS NULL)
ORDER BY 1 DESC
LIMIT 500