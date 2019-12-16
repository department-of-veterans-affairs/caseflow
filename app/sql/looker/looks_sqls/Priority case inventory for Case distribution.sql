SELECT 
	json_extract_path_text(distributions.statistics, 'priority_count')  AS "distributions.priority_case_count",
	TO_CHAR(DATE_TRUNC('week', distributions.completed_at ), 'YYYY-MM-DD') AS "distributions.completed_week"
FROM public.distributions  AS distributions

GROUP BY 1,DATE_TRUNC('week', distributions.completed_at )
ORDER BY 2 DESC
LIMIT 500