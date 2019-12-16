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
	vacols_issues.isscode  AS "vacols_issues.isscode",
	vacols_issues.isslev2  AS "vacols_issues.isslev2",
	vacols_issues.isslev3  AS "vacols_issues.isslev3",
	vacols_issues.issdesc  AS "vacols_issues.issdesc",
	vacols_brieff."BFKEY"  AS "vacols_brieff.bfkey",
	DATE(vacols_brieff."BFDDEC" ) AS "vacols_brieff.bfddec_date",
	vacols_brieff."BFMEMID"  AS "vacols_brieff.bfmemid",
	vacols_staff.snamef  AS "vacols_staff.snamef",
	vacols_staff.snamel  AS "vacols_staff.snamel",
	vacols_issues.isslev1  AS "vacols_issues.isslev1"
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
       IN ('1', '2', '3', '4', '5', '6', '7', '8', '9'))) AND ((vacols_brieff."BFBOARD"  IN ('D1', 'D5'))) AND ((((vacols_brieff."BFDDEC" ) >= (DATE(DATE '2017-10-01')) AND (vacols_brieff."BFDDEC" ) < (DATE(DATE '2018-09-30')))))
GROUP BY 1,2,3,4,5,6,7,8,9,10,11
ORDER BY 7 DESC
LIMIT 1000