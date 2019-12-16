-- raw sql results do not include filled-in values for 'ramp_elections.established_date'


SELECT 
	DATE(ramp_elections.established_at ) AS "ramp_elections.established_date",
	COUNT(*) AS "ramp_elections.count"
FROM public.ramp_elections  AS ramp_elections

WHERE 
	(ramp_elections.established_at  IS NOT NULL)
GROUP BY 1
ORDER BY 1 DESC
LIMIT 500