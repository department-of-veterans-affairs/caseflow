SELECT 
	intakes.veteran_file_number  AS "intakes.veteran_file_number",
	users.station_id  AS "users.station_id",
	users.full_name  AS "users.full_name",
	DATE(intakes.started_at ) AS "intakes.started_date",
	intakes.completion_status  AS "intakes.completion_status"
FROM public.intakes  AS intakes
LEFT JOIN public.users  AS users ON intakes.user_id = users.id 

WHERE (intakes.completion_status = 'success') AND (intakes.type = 'AppealIntake') AND (users.station_id <> '101' OR users.station_id IS NULL)
GROUP BY 1,2,3,4,5
ORDER BY 2 DESC
LIMIT 500