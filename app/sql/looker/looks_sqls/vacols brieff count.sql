WITH vacols_brieff AS (select *, ((select count(*) into dcnt from vacols.assign
            where tsktknm = bf.bfkey  and tskactcd in ('B', 'B1', 'B2')
        ) +
        (select count(*) into hcnt from vacols.hearsched where folder_nr = bf.bfkey
          and hearing_type in ('C', 'T', 'V') and aod in ('G', 'Y'))
        ) as aod_count
         from vacols.brieff bf
        )
SELECT 
	COUNT(*) AS "vacols_brieff.count"
FROM vacols_brieff

LIMIT 500