SELECT 
	vacols_corres."STAFKEY"  AS "vacols_corres.stafkey",
	vacols_corres."SNOTES"  AS "vacols_corres.snotes",
	TO_CHAR(to_timestamp(vacols_corres."SNOTES", 'YYYY-MM-DD HH24:MI:SS'), 'YYYY-MM-DD HH24:MI:SS') AS "vacols_corres.snotes_date_time"
FROM "VACOLS"."CORRES"  AS vacols_corres

WHERE ((to_timestamp(vacols_corres."SNOTES", 'YYYY-MM-DD HH24:MI:SS') < (DATEADD(day,-1, DATE_TRUNC('day',GETDATE()) )))) AND (((vacols_corres."STAFKEY") = '3479B8F9'))
GROUP BY 1,2,3
ORDER BY 3 DESC
LIMIT 500