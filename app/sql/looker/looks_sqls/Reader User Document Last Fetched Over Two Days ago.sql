-- raw sql results do not include filled-in values for 'reader_users.documents_fetched_date'


SELECT 
	DATE(reader_users.documents_fetched_at ) AS "reader_users.documents_fetched_date",
	COUNT(*) AS "reader_users.count"
FROM public.reader_users  AS reader_users

WHERE 
	(reader_users.documents_fetched_at  < (DATEADD(day,-2, DATE_TRUNC('day',GETDATE()) )))
GROUP BY 1
ORDER BY 1 DESC
LIMIT 500