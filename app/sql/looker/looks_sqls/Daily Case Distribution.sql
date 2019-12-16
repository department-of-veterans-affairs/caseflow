SELECT 
	DATE(distributions.completed_at ) AS "distributions.completed_date",
	COUNT(distributed_cases.id ) AS "distributed_cases.count"
FROM public.distributions  AS distributions
LEFT JOIN public.distributed_cases  AS distributed_cases ON distributions.id = distributed_cases.distribution_id 

GROUP BY 1
HAVING 
	NOT (COUNT(distributed_cases.id ) IS NULL)
ORDER BY 1 
LIMIT 500