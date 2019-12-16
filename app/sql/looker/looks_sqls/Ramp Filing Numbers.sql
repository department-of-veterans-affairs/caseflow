SELECT 
	ramp_refilings.appeal_docket  AS "ramp_refilings.appeal_docket",
	ramp_refilings.option_selected  AS "ramp_refilings.option_selected",
	COUNT(*) AS "ramp_refilings.count"
FROM public.ramp_refilings  AS ramp_refilings

WHERE 
	(ramp_refilings.receipt_date  < (DATE(DATE '2018-10-15')))
GROUP BY 1,2
ORDER BY 1 
LIMIT 500

-- sql for creating the total and/or determining pivot columns
SELECT 
	COUNT(*) AS "ramp_refilings.count"
FROM public.ramp_refilings  AS ramp_refilings

WHERE 
	(ramp_refilings.receipt_date  < (DATE(DATE '2018-10-15')))
LIMIT 1