SELECT 
	appeals.veteran_file_number  AS "appeals.veteran_file_number",
	DATE(appeals.receipt_date ) AS "appeals.receipt_date",
	DATE(appeals.established_at ) AS "appeals.established_date"
FROM public.appeals  AS appeals

WHERE 
	(((appeals.established_at ) >= (TIMESTAMP '2019-06-01') AND (appeals.established_at ) < (TIMESTAMP '2019-06-30')))
GROUP BY 1,2,3
ORDER BY 2 DESC
LIMIT 5000