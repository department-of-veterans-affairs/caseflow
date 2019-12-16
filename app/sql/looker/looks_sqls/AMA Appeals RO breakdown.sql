SELECT 
	appeals.closest_regional_office  AS "appeals.closest_regional_office",
	COUNT(*) AS "appeals.count"
FROM public.appeals  AS appeals

WHERE 
	((appeals.closest_regional_office IS NOT NULL))
GROUP BY 1
ORDER BY 1 