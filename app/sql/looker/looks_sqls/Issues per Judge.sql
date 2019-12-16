WITH vacols_brieff AS (select *, ((select count(*) into dcnt from vacols.assign
            where tsktknm = bf.bfkey  and tskactcd in ('B', 'B1', 'B2')
        ) +
        (select count(*) into hcnt from vacols.hearsched where folder_nr = bf.bfkey
          and hearing_type in ('C', 'T', 'V') and aod in ('G', 'Y'))
        ) as aod_count
         from vacols.brieff bf
        )
SELECT * FROM (
SELECT *, DENSE_RANK() OVER (ORDER BY z___min_rank) as z___pivot_row_rank, RANK() OVER (PARTITION BY z__pivot_col_rank ORDER BY z___min_rank) as z__pivot_col_ordering FROM (
SELECT *, MIN(z___rank) OVER (PARTITION BY "vacols_brieff.bfmemid","vacols_staff.snamef","vacols_staff.snamel") as z___min_rank FROM (
SELECT *, RANK() OVER (ORDER BY CASE WHEN z__pivot_col_rank=7 THEN 1 ELSE 2 END, CASE WHEN z__pivot_col_rank=7 THEN "vacols_issues.issdc_count" ELSE NULL END DESC NULLS LAST, "vacols_issues.issdc_count" DESC, z__pivot_col_rank, "vacols_brieff.bfmemid", "vacols_staff.snamef", "vacols_staff.snamel") AS z___rank FROM (
SELECT *, DENSE_RANK() OVER (ORDER BY "vacols_issues.issdc" NULLS LAST) AS z__pivot_col_rank FROM (
SELECT 
	CASE
        WHEN vacols_issues.issdc = '1' THEN 'Allowed'
        WHEN vacols_issues.issdc = '3' THEN 'Remanded'
        WHEN vacols_issues.issdc = '4' THEN 'Denied'
        WHEN vacols_issues.issdc = '5' THEN 'Vacated'
        WHEN vacols_issues.issdc = '6' THEN 'Dismissed, Withdrawn'
        WHEN vacols_issues.issdc = '8' THEN 'Dismissed, Death'
        ELSE vacols_issues.issdc
      END
       AS "vacols_issues.issdc",
	vacols_brieff."BFMEMID"  AS "vacols_brieff.bfmemid",
	vacols_staff.snamef  AS "vacols_staff.snamef",
	vacols_staff.snamel  AS "vacols_staff.snamel",
	COUNT(*) AS "vacols_issues.issdc_count"
FROM vacols.issues  AS vacols_issues
LEFT JOIN vacols_brieff ON vacols_issues.isskey = (vacols_brieff."BFKEY") 
LEFT JOIN vacols.staff  AS vacols_staff ON (vacols_brieff."BFMEMID") = vacols_staff.sattyid 

WHERE ((CASE
        WHEN vacols_issues.issdc = '1' THEN 'Allowed'
        WHEN vacols_issues.issdc = '3' THEN 'Remanded'
        WHEN vacols_issues.issdc = '4' THEN 'Denied'
        WHEN vacols_issues.issdc = '5' THEN 'Vacated'
        WHEN vacols_issues.issdc = '6' THEN 'Dismissed, Withdrawn'
        WHEN vacols_issues.issdc = '8' THEN 'Dismissed, Death'
        ELSE vacols_issues.issdc
      END
       IN ('Allowed', 'Remanded', 'Denied', 'Dismissed, Death', 'Dismissed, Withdrawn', 'Vacated'))) AND ((vacols_brieff."BFBOARD"  IN ('D1', 'D5'))) AND ((((vacols_brieff."BFDDEC" ) >= (DATE(DATE '2017-10-01')) AND (vacols_brieff."BFDDEC" ) < (DATE(DATE '2018-09-30')))))
GROUP BY 1,2,3,4) ww
) bb WHERE z__pivot_col_rank <= 16384
) aa
) xx
) zz
 WHERE z___pivot_row_rank <= 1000 OR z__pivot_col_ordering = 1 ORDER BY z___pivot_row_rank

-- sql for creating the total and/or determining pivot columns
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
        WHEN vacols_issues.issdc = '1' THEN 'Allowed'
        WHEN vacols_issues.issdc = '3' THEN 'Remanded'
        WHEN vacols_issues.issdc = '4' THEN 'Denied'
        WHEN vacols_issues.issdc = '5' THEN 'Vacated'
        WHEN vacols_issues.issdc = '6' THEN 'Dismissed, Withdrawn'
        WHEN vacols_issues.issdc = '8' THEN 'Dismissed, Death'
        ELSE vacols_issues.issdc
      END
       AS "vacols_issues.issdc",
	COUNT(*) AS "vacols_issues.issdc_count"
FROM vacols.issues  AS vacols_issues
LEFT JOIN vacols_brieff ON vacols_issues.isskey = (vacols_brieff."BFKEY") 
LEFT JOIN vacols.staff  AS vacols_staff ON (vacols_brieff."BFMEMID") = vacols_staff.sattyid 

WHERE ((CASE
        WHEN vacols_issues.issdc = '1' THEN 'Allowed'
        WHEN vacols_issues.issdc = '3' THEN 'Remanded'
        WHEN vacols_issues.issdc = '4' THEN 'Denied'
        WHEN vacols_issues.issdc = '5' THEN 'Vacated'
        WHEN vacols_issues.issdc = '6' THEN 'Dismissed, Withdrawn'
        WHEN vacols_issues.issdc = '8' THEN 'Dismissed, Death'
        ELSE vacols_issues.issdc
      END
       IN ('Allowed', 'Remanded', 'Denied', 'Dismissed, Death', 'Dismissed, Withdrawn', 'Vacated'))) AND ((vacols_brieff."BFBOARD"  IN ('D1', 'D5'))) AND ((((vacols_brieff."BFDDEC" ) >= (DATE(DATE '2017-10-01')) AND (vacols_brieff."BFDDEC" ) < (DATE(DATE '2018-09-30')))))
GROUP BY 1
ORDER BY 1 
LIMIT 1000

-- sql for creating the pivot row totals
WITH vacols_brieff AS (select *, ((select count(*) into dcnt from vacols.assign
            where tsktknm = bf.bfkey  and tskactcd in ('B', 'B1', 'B2')
        ) +
        (select count(*) into hcnt from vacols.hearsched where folder_nr = bf.bfkey
          and hearing_type in ('C', 'T', 'V') and aod in ('G', 'Y'))
        ) as aod_count
         from vacols.brieff bf
        )
SELECT 
	vacols_brieff."BFMEMID"  AS "vacols_brieff.bfmemid",
	vacols_staff.snamef  AS "vacols_staff.snamef",
	vacols_staff.snamel  AS "vacols_staff.snamel",
	COUNT(*) AS "vacols_issues.issdc_count"
FROM vacols.issues  AS vacols_issues
LEFT JOIN vacols_brieff ON vacols_issues.isskey = (vacols_brieff."BFKEY") 
LEFT JOIN vacols.staff  AS vacols_staff ON (vacols_brieff."BFMEMID") = vacols_staff.sattyid 

WHERE ((CASE
        WHEN vacols_issues.issdc = '1' THEN 'Allowed'
        WHEN vacols_issues.issdc = '3' THEN 'Remanded'
        WHEN vacols_issues.issdc = '4' THEN 'Denied'
        WHEN vacols_issues.issdc = '5' THEN 'Vacated'
        WHEN vacols_issues.issdc = '6' THEN 'Dismissed, Withdrawn'
        WHEN vacols_issues.issdc = '8' THEN 'Dismissed, Death'
        ELSE vacols_issues.issdc
      END
       IN ('Allowed', 'Remanded', 'Denied', 'Dismissed, Death', 'Dismissed, Withdrawn', 'Vacated'))) AND ((vacols_brieff."BFBOARD"  IN ('D1', 'D5'))) AND ((((vacols_brieff."BFDDEC" ) >= (DATE(DATE '2017-10-01')) AND (vacols_brieff."BFDDEC" ) < (DATE(DATE '2018-09-30')))))
GROUP BY 1,2,3
ORDER BY 4 DESC
LIMIT 30000

-- sql for creating the grand totals
WITH vacols_brieff AS (select *, ((select count(*) into dcnt from vacols.assign
            where tsktknm = bf.bfkey  and tskactcd in ('B', 'B1', 'B2')
        ) +
        (select count(*) into hcnt from vacols.hearsched where folder_nr = bf.bfkey
          and hearing_type in ('C', 'T', 'V') and aod in ('G', 'Y'))
        ) as aod_count
         from vacols.brieff bf
        )
SELECT 
	COUNT(*) AS "vacols_issues.issdc_count"
FROM vacols.issues  AS vacols_issues
LEFT JOIN vacols_brieff ON vacols_issues.isskey = (vacols_brieff."BFKEY") 
LEFT JOIN vacols.staff  AS vacols_staff ON (vacols_brieff."BFMEMID") = vacols_staff.sattyid 

WHERE ((CASE
        WHEN vacols_issues.issdc = '1' THEN 'Allowed'
        WHEN vacols_issues.issdc = '3' THEN 'Remanded'
        WHEN vacols_issues.issdc = '4' THEN 'Denied'
        WHEN vacols_issues.issdc = '5' THEN 'Vacated'
        WHEN vacols_issues.issdc = '6' THEN 'Dismissed, Withdrawn'
        WHEN vacols_issues.issdc = '8' THEN 'Dismissed, Death'
        ELSE vacols_issues.issdc
      END
       IN ('Allowed', 'Remanded', 'Denied', 'Dismissed, Death', 'Dismissed, Withdrawn', 'Vacated'))) AND ((vacols_brieff."BFBOARD"  IN ('D1', 'D5'))) AND ((((vacols_brieff."BFDDEC" ) >= (DATE(DATE '2017-10-01')) AND (vacols_brieff."BFDDEC" ) < (DATE(DATE '2018-09-30')))))
LIMIT 1