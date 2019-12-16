SELECT 
	TO_CHAR(users.efolder_documents_fetched_at , 'YYYY-MM-DD HH24:MI:SS') AS "users.efolder_documents_fetched_at_time"
FROM public.reader_users  AS reader_users
LEFT JOIN public.users  AS users ON reader_users.user_id = users.id 

WHERE 
	(((users.efolder_documents_fetched_at ) >= ((DATEADD(minute,-29, DATE_TRUNC('minute', GETDATE()) ))) AND (users.efolder_documents_fetched_at ) < ((DATEADD(minute,30, DATEADD(minute,-29, DATE_TRUNC('minute', GETDATE()) ) )))))
GROUP BY 1
ORDER BY 1 DESC
LIMIT 500