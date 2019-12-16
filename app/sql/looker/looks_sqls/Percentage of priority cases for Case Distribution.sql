SELECT 
	distributions.id  AS "distributions.id",
	vacols_staff.snamel  AS "vacols_staff.snamel",
	vacols_staff.snamef  AS "vacols_staff.snamef",
	DATE(distributions.completed_at ) AS "distributions.completed_date",
	COUNT(CASE WHEN (distributed_cases.priority = 'true') THEN 1 ELSE NULL END) AS "distributed_cases.judge_priority_count",
	COUNT(distributed_cases.id ) AS "distributed_cases.count"
FROM public.distributions  AS distributions
LEFT JOIN public.distributed_cases  AS distributed_cases ON distributions.id = distributed_cases.distribution_id 
LEFT JOIN vacols.staff  AS vacols_staff ON distributions.judge_id = vacols_staff.sattyid 

GROUP BY 1,2,3,4
ORDER BY 4 
LIMIT 500