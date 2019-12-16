SELECT 
	ramp_refilings.appeal_docket  AS "ramp_refilings.appeal_docket",
	ramp_refilings.option_selected  AS "ramp_refilings.option_selected",
	COUNT(*) AS "ramp_refilings.count"
FROM public.ramp_refilings  AS ramp_refilings

WHERE 
	(ramp_refilings.option_selected = 'appeal')
GROUP BY 1,2
ORDER BY 3 DESC
LIMIT 500

-- sql for creating the total and/or determining pivot columns
SELECT 
	COUNT(*) AS "ramp_refilings.count"
FROM public.ramp_refilings  AS ramp_refilings

WHERE 
	(ramp_refilings.option_selected = 'appeal')
LIMIT 1