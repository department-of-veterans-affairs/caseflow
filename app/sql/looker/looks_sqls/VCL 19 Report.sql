WITH vacols_brieff AS (select *, ((select count(*) into dcnt from vacols.assign
            where tsktknm = bf.bfkey  and tskactcd in ('B', 'B1', 'B2')
        ) +
        (select count(*) into hcnt from vacols.hearsched where folder_nr = bf.bfkey
          and hearing_type in ('C', 'T', 'V') and aod in ('G', 'Y'))
        ) as aod_count
         from vacols.brieff bf
        )
SELECT 
	vacols_brieff."BFDC"  AS "vacols_brieff.bfdc",
	vacols_brieff."BFHA"  AS "vacols_brieff.bfha",
	vacols_brieff."BFAC"  AS "vacols_brieff.bfac",
	CASE
        WHEN (vacols_brieff."BFAC") = 1 THEN 'Original'
        WHEN (vacols_brieff."BFAC") = 2 THEN 'Supplemental'
        WHEN (vacols_brieff."BFAC") = 3 THEN 'Post Remand'
        WHEN (vacols_brieff."BFAC") = 4 THEN 'Reconsideration'
        WHEN (vacols_brieff."BFAC") = 5 THEN 'Vacated'
        WHEN (vacols_brieff."BFAC") = 6 THEN 'De Novo'
        WHEN (vacols_brieff."BFAC") = 7 THEN 'Court Remand'
        WHEN (vacols_brieff."BFAC") = 8 THEN 'Designation of Record'
        WHEN (vacols_brieff."BFAC") = 9 THEN 'CUE'
        ELSE (vacols_brieff."BFAC")
      END
       AS "vacols_brieff.bfac_translated",
	vacols_brieff."BFBOARD"  AS "vacols_brieff.bfboard",
	vacols_brieff."BFREGOFF"  AS "vacols_brieff.bfregoff"
FROM vacols_brieff

GROUP BY 1,2,3,4,5,6
ORDER BY 1 
LIMIT 500