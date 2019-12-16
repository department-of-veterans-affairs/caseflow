SELECT 
	COUNT(*) AS "vacols_staff.count"
FROM vacols.staff  AS vacols_staff

WHERE (vacols_staff.sactive = 'A') AND ((vacols_staff.sattyid IS NOT NULL)) AND (vacols_staff.svlj <> 'J' OR vacols_staff.svlj IS NULL)
LIMIT 500