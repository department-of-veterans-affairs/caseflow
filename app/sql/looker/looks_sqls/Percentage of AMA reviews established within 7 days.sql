SELECT 
	intakes.veteran_file_number  AS "intakes.veteran_file_number",
	DATE(intakes.started_at ) AS "intakes.started_date",
	DATE(intakes.completed_at ) AS "intakes.completed_date"
FROM public.intakes  AS intakes

WHERE ((((intakes.started_at ) >= (TIMESTAMP '2019-06-01') AND (intakes.started_at ) < (TIMESTAMP '2019-06-30')))) AND (intakes.type = 'AppealIntake')
GROUP BY 1,2,3
ORDER BY 2 DESC
LIMIT 5000