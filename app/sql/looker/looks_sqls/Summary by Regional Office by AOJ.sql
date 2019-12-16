WITH vacols_brieff AS (select *, ((select count(*) into dcnt from vacols.assign
            where tsktknm = bf.bfkey  and tskactcd in ('B', 'B1', 'B2')
        ) +
        (select count(*) into hcnt from vacols.hearsched where folder_nr = bf.bfkey
          and hearing_type in ('C', 'T', 'V') and aod in ('G', 'Y'))
        ) as aod_count
         from vacols.brieff bf
        )
SELECT 
	CASE
        WHEN vacols_hearsched.hearing_type = 'C' THEN 'Central'
        WHEN vacols_hearsched.hearing_type = 'T' THEN 'Travel'
        WHEN vacols_hearsched.hearing_type = 'V' THEN 'Video'
        ELSE vacols_hearsched.hearing_type
      END
       AS "vacols_hearsched.hearing_type",
	DATE(vacols_hearsched.hearing_date ) AS "vacols_hearsched.hearing_date",
	CASE
        WHEN vacols_hearsched.hearing_disp = 'C' THEN 'Canceled'
        WHEN vacols_hearsched.hearing_disp = 'H' THEN 'Held'
        WHEN vacols_hearsched.hearing_disp = 'N' THEN 'No Show'
        WHEN vacols_hearsched.hearing_disp = 'P' THEN 'Postponed'
        WHEN vacols_hearsched.hearing_disp = 'W' THEN 'Widthrawn'
        ELSE vacols_hearsched.hearing_disp
      END
       AS "vacols_hearsched.hearing_disp",
	vacols_hearsched.team  AS "vacols_hearsched.team",
	DATE(vacols_brieff."BFD19" ) AS "vacols_brieff.bfd19_date",
	vacols_brieff."BFREGOFF"  AS "vacols_brieff.bfregoff",
	vacols_hearsched.board_member  AS "vacols_hearsched.board_member"
FROM vacols.hearsched  AS vacols_hearsched
LEFT JOIN vacols_brieff ON vacols_hearsched.folder_nr = (vacols_brieff."BFKEY") 

WHERE ((vacols_hearsched.board_member IS NOT NULL) AND (vacols_hearsched.board_member IS NOT NULL AND LENGTH(vacols_hearsched.board_member ) <> 0 )) AND ((((vacols_hearsched.hearing_date ) >= (TIMESTAMP '2017-04-01') AND (vacols_hearsched.hearing_date ) < (TIMESTAMP '2018-03-31')))) AND ((((CASE
        WHEN vacols_hearsched.hearing_disp = 'C' THEN 'Canceled'
        WHEN vacols_hearsched.hearing_disp = 'H' THEN 'Held'
        WHEN vacols_hearsched.hearing_disp = 'N' THEN 'No Show'
        WHEN vacols_hearsched.hearing_disp = 'P' THEN 'Postponed'
        WHEN vacols_hearsched.hearing_disp = 'W' THEN 'Widthrawn'
        ELSE vacols_hearsched.hearing_disp
      END) IS NOT NULL))) AND ((CASE
        WHEN vacols_hearsched.hearing_type = 'C' THEN 'Central'
        WHEN vacols_hearsched.hearing_type = 'T' THEN 'Travel'
        WHEN vacols_hearsched.hearing_type = 'V' THEN 'Video'
        ELSE vacols_hearsched.hearing_type
      END
       IN ('V', 'C', 'T')))
GROUP BY 1,2,3,4,5,6,7
ORDER BY 7 DESC
LIMIT 500