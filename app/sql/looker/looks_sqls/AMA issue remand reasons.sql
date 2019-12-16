SELECT 
	remand_reasons.code  AS "remand_reasons.code",
	request_issues.disposition  AS "request_issues.disposition",
	COUNT(*) AS "remand_reasons.remand_reason_code_count"
FROM public.remand_reasons  AS remand_reasons
LEFT JOIN public.request_issues  AS request_issues ON remand_reasons.request_issue_id = request_issues.id

WHERE 
	(request_issues.disposition = 'remanded')
GROUP BY 1,2
ORDER BY 3 DESC
LIMIT 500