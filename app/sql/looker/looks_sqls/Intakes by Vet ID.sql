SELECT 
	intakes.veteran_file_number  AS "intakes.veteran_file_number",
	users.full_name  AS "users.full_name",
	intakes.type  AS "intakes.type",
	DATE(intakes.completed_at ) AS "intakes.completed_date"
FROM public.intakes  AS intakes
LEFT JOIN public.users  AS users ON intakes.user_id = users.id 

WHERE (intakes.completion_status = 'success') AND (intakes.veteran_file_number = '102305870')
GROUP BY 1,2,3,4
ORDER BY 1 
LIMIT 500