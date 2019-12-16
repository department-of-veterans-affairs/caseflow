-- raw sql results do not include filled-in values for 'ramp_elections.established_month'


SELECT 
	TO_CHAR(DATE_TRUNC('month', ramp_elections.established_at ), 'YYYY-MM') AS "ramp_elections.established_month",
	COUNT(*) AS "ramp_elections.count"
FROM public.ramp_elections  AS ramp_elections

GROUP BY DATE_TRUNC('month', ramp_elections.established_at )
ORDER BY 1 DESC
LIMIT 500