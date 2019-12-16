SELECT 
	hearings.disposition  AS "hearings.disposition",
	COUNT(DISTINCT appeals.id ) AS "appeals.count"
FROM public.hearings  AS hearings
LEFT JOIN public.appeals  AS appeals ON hearings.appeal_id = appeals.id 
LEFT JOIN public.hearing_days  AS hearing_days ON hearings.hearing_day_id = hearing_days.id 

WHERE 
	(((hearing_days.scheduled_for ) >= (DATE(DATE '2019-06-01')) AND (hearing_days.scheduled_for ) < (DATE(DATE '2019-06-30'))))
GROUP BY 1
ORDER BY 2 DESC
LIMIT 500

-- sql for creating the total and/or determining pivot columns
SELECT 
	COUNT(DISTINCT appeals.id ) AS "appeals.count"
FROM public.hearings  AS hearings
LEFT JOIN public.appeals  AS appeals ON hearings.appeal_id = appeals.id 
LEFT JOIN public.hearing_days  AS hearing_days ON hearings.hearing_day_id = hearing_days.id 

WHERE 
	(((hearing_days.scheduled_for ) >= (DATE(DATE '2019-06-01')) AND (hearing_days.scheduled_for ) < (DATE(DATE '2019-06-30'))))
LIMIT 1