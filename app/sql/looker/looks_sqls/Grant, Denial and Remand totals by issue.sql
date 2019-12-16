SELECT 
	request_issues.disposition  AS "request_issues.disposition",
	COUNT(*) AS "request_issues.count"
FROM public.request_issues  AS request_issues

WHERE 
	((request_issues.disposition IS NOT NULL))
GROUP BY 1
ORDER BY 2 DESC
LIMIT 500

-- sql for creating the total and/or determining pivot columns
SELECT 
	COUNT(*) AS "request_issues.count"
FROM public.request_issues  AS request_issues

WHERE 
	((request_issues.disposition IS NOT NULL))
LIMIT 1