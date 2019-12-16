SELECT 
	intakes.veteran_file_number  AS "intakes.veteran_file_number",
	DATE(intakes.started_at ) AS "intakes.started_date",
	users.full_name  AS "users.full_name"
FROM public.intakes  AS intakes
LEFT JOIN public.users  AS users ON intakes.user_id = users.id 

WHERE (intakes.completion_status = 'success') AND ((users.full_name  IN ('CHRISTOPHER HARRIS', 'JESSICA HAMILTON', 'JOHN BARFIELD', 'MARIAM IBRAHIM', 'MATTHEW SOLANO', 'ROBIN BROWN', 'SHANTEL GRAYSON', 'TETYANA LEW')))
GROUP BY 1,2,3
ORDER BY 2 DESC
LIMIT 2000