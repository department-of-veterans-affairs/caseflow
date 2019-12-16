SELECT 
	ramp_refilings.appeal_docket  AS "ramp_refilings.appeal_docket",
	ramp_refilings.option_selected  AS "ramp_refilings.option_selected",
	COUNT(*) AS "ramp_refilings.count"
FROM public.ramp_refilings  AS ramp_refilings

GROUP BY 1,2
ORDER BY 1 
LIMIT 500