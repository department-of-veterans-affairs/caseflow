SELECT 
	appeals.veteran_file_number  AS "appeals.veteran_file_number",
	appeals.docket_type  AS "appeals.docket_type",
	to_char((DATE(appeals.receipt_date )), 'yymmdd') || '-' || appeals.id  AS "appeals.docket_number",
	DATE(appeals.established_at ) AS "appeals.established_date"
FROM public.tasks  AS tasks
LEFT JOIN public.appeals  AS appeals ON tasks.appeal_id = appeals.id AND tasks.appeal_type = 'Appeal'

WHERE 
	(((appeals.established_at ) >= (TIMESTAMP '2019-06-01') AND (appeals.established_at ) < (TIMESTAMP '2019-06-30')))
GROUP BY 1,2,3,4
ORDER BY 4 DESC
LIMIT 2000