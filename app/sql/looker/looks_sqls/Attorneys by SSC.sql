SELECT 
	vacols_staff.smemgrp  AS "vacols_staff.smemgrp",
	COUNT(*) AS "vacols_staff.count"
FROM vacols.staff  AS vacols_staff

WHERE (vacols_staff.sactive = 'A') AND (((vacols_staff.smemgrp IS NOT NULL) AND vacols_staff.smemgrp <> '1220'))
GROUP BY 1
ORDER BY 1 DESC
LIMIT 1000