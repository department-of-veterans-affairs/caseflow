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
SELECT *, MIN(z___rank) OVER (PARTITION BY "vacols_brieff.bfac_translated") as z___min_rank FROM (
SELECT *, RANK() OVER (ORDER BY CASE WHEN z__pivot_col_rank=1 THEN 1 ELSE 2 END, CASE WHEN z__pivot_col_rank=1 THEN "vacols_brieff.action_decision_count" ELSE NULL END DESC NULLS LAST, "vacols_brieff.action_decision_count" DESC, z__pivot_col_rank, "vacols_brieff.bfac_translated") AS z___rank FROM (
SELECT *, DENSE_RANK() OVER (ORDER BY "vacols_brieff.bfdc" NULLS LAST) AS z__pivot_col_rank FROM (
SELECT 
	vacols_brieff."BFDC"  AS "vacols_brieff.bfdc",
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
	COUNT(*) AS "vacols_brieff.action_decision_count"
FROM vacols_brieff

WHERE ((vacols_brieff."BFAC"  IN ('1', '2', '3', '4', '5', '6', '8', '9', '7'))) AND ((vacols_brieff."BFDC"  IN ('1', '2', '3', '4', '5', '6', '7', '8', '9'))) AND ((((vacols_brieff."BFDDEC" ) >= (DATE(DATE '2017-10-01')) AND (vacols_brieff."BFDDEC" ) < (DATE(DATE '2018-09-02')))))
GROUP BY 1,2) ww
) bb WHERE z__pivot_col_rank <= 16384
) aa
) xx
) zz
 WHERE z___pivot_row_rank <= 500 OR z__pivot_col_ordering = 1 ORDER BY z___pivot_row_rank

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
	vacols_brieff."BFDC"  AS "vacols_brieff.bfdc",
	COUNT(*) AS "vacols_brieff.action_decision_count"
FROM vacols_brieff

WHERE ((vacols_brieff."BFAC"  IN ('1', '2', '3', '4', '5', '6', '8', '9', '7'))) AND ((vacols_brieff."BFDC"  IN ('1', '2', '3', '4', '5', '6', '7', '8', '9'))) AND ((((vacols_brieff."BFDDEC" ) >= (DATE(DATE '2017-10-01')) AND (vacols_brieff."BFDDEC" ) < (DATE(DATE '2018-09-02')))))
GROUP BY 1
ORDER BY 1 
LIMIT 500

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
	COUNT(*) AS "vacols_brieff.action_decision_count"
FROM vacols_brieff

WHERE ((vacols_brieff."BFAC"  IN ('1', '2', '3', '4', '5', '6', '8', '9', '7'))) AND ((vacols_brieff."BFDC"  IN ('1', '2', '3', '4', '5', '6', '7', '8', '9'))) AND ((((vacols_brieff."BFDDEC" ) >= (DATE(DATE '2017-10-01')) AND (vacols_brieff."BFDDEC" ) < (DATE(DATE '2018-09-02')))))
GROUP BY 1
ORDER BY 2 DESC
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
	COUNT(*) AS "vacols_brieff.action_decision_count"
FROM vacols_brieff

WHERE ((vacols_brieff."BFAC"  IN ('1', '2', '3', '4', '5', '6', '8', '9', '7'))) AND ((vacols_brieff."BFDC"  IN ('1', '2', '3', '4', '5', '6', '7', '8', '9'))) AND ((((vacols_brieff."BFDDEC" ) >= (DATE(DATE '2017-10-01')) AND (vacols_brieff."BFDDEC" ) < (DATE(DATE '2018-09-02')))))
LIMIT 1