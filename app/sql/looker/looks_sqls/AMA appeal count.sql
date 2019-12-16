SELECT 
	appeals.docket_type  AS "appeals.docket_type",
	COUNT(*) AS "appeals.count"
FROM public.appeals  AS appeals

WHERE 
	(appeals.established_at  IS NOT NULL)
GROUP BY 1
ORDER BY 1 
LIMIT 500

-- sql for creating the total and/or determining pivot columns
SELECT 
	COUNT(*) AS "appeals.count"
FROM public.appeals  AS appeals

WHERE 
	(appeals.established_at  IS NOT NULL)
LIMIT 1