SELECT * FROM (
SELECT *, DENSE_RANK() OVER (ORDER BY z___min_rank) as z___pivot_row_rank, RANK() OVER (PARTITION BY z__pivot_col_rank ORDER BY z___min_rank) as z__pivot_col_ordering FROM (
SELECT *, MIN(z___rank) OVER (PARTITION BY "vacols_hearsched.team","vacols_hearsched.board_member","vacols_staff.snamef","vacols_staff.snamel") as z___min_rank FROM (
SELECT *, RANK() OVER (ORDER BY CASE WHEN z__pivot_col_rank=5 THEN 1 ELSE 2 END, CASE WHEN z__pivot_col_rank=5 THEN "vacols_hearsched.hearing_result_count" ELSE NULL END DESC NULLS LAST, "vacols_hearsched.hearing_result_count" DESC, z__pivot_col_rank, "vacols_hearsched.team", "vacols_hearsched.board_member", "vacols_staff.snamef", "vacols_staff.snamel") AS z___rank FROM (
SELECT *, DENSE_RANK() OVER (ORDER BY "vacols_hearsched.hearing_type" NULLS LAST, "vacols_hearsched.hearing_disp" NULLS LAST) AS z__pivot_col_rank FROM (
SELECT 
	CASE
        WHEN vacols_hearsched.hearing_type = 'C' THEN 'Central'
        WHEN vacols_hearsched.hearing_type = 'T' THEN 'Travel'
        WHEN vacols_hearsched.hearing_type = 'V' THEN 'Video'
        ELSE vacols_hearsched.hearing_type
      END
       AS "vacols_hearsched.hearing_type",
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
	vacols_hearsched.board_member  AS "vacols_hearsched.board_member",
	vacols_staff.snamef  AS "vacols_staff.snamef",
	vacols_staff.snamel  AS "vacols_staff.snamel",
	COUNT(*) AS "vacols_hearsched.hearing_result_count"
FROM vacols.hearsched  AS vacols_hearsched
LEFT JOIN vacols.staff  AS vacols_staff ON vacols_hearsched.board_member = vacols_staff.sattyid 

WHERE ((vacols_hearsched.board_member IS NOT NULL) AND (vacols_hearsched.board_member IS NOT NULL AND LENGTH(vacols_hearsched.board_member ) <> 0 )) AND ((((vacols_hearsched.hearing_date ) >= (TIMESTAMP '2017-10-01') AND (vacols_hearsched.hearing_date ) < (TIMESTAMP '2018-09-09')))) AND ((((CASE
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
       IN ('Video', 'Central', 'Travel')))
GROUP BY 1,2,3,4,5,6) ww
) bb WHERE z__pivot_col_rank <= 16384
) aa
) xx
) zz
 WHERE z___pivot_row_rank <= 500 OR z__pivot_col_ordering = 1 ORDER BY z___pivot_row_rank

-- sql for creating the total and/or determining pivot columns
SELECT 
	CASE
        WHEN vacols_hearsched.hearing_type = 'C' THEN 'Central'
        WHEN vacols_hearsched.hearing_type = 'T' THEN 'Travel'
        WHEN vacols_hearsched.hearing_type = 'V' THEN 'Video'
        ELSE vacols_hearsched.hearing_type
      END
       AS "vacols_hearsched.hearing_type",
	CASE
        WHEN vacols_hearsched.hearing_disp = 'C' THEN 'Canceled'
        WHEN vacols_hearsched.hearing_disp = 'H' THEN 'Held'
        WHEN vacols_hearsched.hearing_disp = 'N' THEN 'No Show'
        WHEN vacols_hearsched.hearing_disp = 'P' THEN 'Postponed'
        WHEN vacols_hearsched.hearing_disp = 'W' THEN 'Widthrawn'
        ELSE vacols_hearsched.hearing_disp
      END
       AS "vacols_hearsched.hearing_disp",
	COUNT(*) AS "vacols_hearsched.hearing_result_count"
FROM vacols.hearsched  AS vacols_hearsched
LEFT JOIN vacols.staff  AS vacols_staff ON vacols_hearsched.board_member = vacols_staff.sattyid 

WHERE ((vacols_hearsched.board_member IS NOT NULL) AND (vacols_hearsched.board_member IS NOT NULL AND LENGTH(vacols_hearsched.board_member ) <> 0 )) AND ((((vacols_hearsched.hearing_date ) >= (TIMESTAMP '2017-10-01') AND (vacols_hearsched.hearing_date ) < (TIMESTAMP '2018-09-09')))) AND ((((CASE
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
       IN ('Video', 'Central', 'Travel')))
GROUP BY 1,2
ORDER BY 1 ,2 
LIMIT 500

-- sql for creating the pivot row totals
SELECT 
	vacols_hearsched.team  AS "vacols_hearsched.team",
	vacols_hearsched.board_member  AS "vacols_hearsched.board_member",
	vacols_staff.snamef  AS "vacols_staff.snamef",
	vacols_staff.snamel  AS "vacols_staff.snamel",
	COUNT(*) AS "vacols_hearsched.hearing_result_count"
FROM vacols.hearsched  AS vacols_hearsched
LEFT JOIN vacols.staff  AS vacols_staff ON vacols_hearsched.board_member = vacols_staff.sattyid 

WHERE ((vacols_hearsched.board_member IS NOT NULL) AND (vacols_hearsched.board_member IS NOT NULL AND LENGTH(vacols_hearsched.board_member ) <> 0 )) AND ((((vacols_hearsched.hearing_date ) >= (TIMESTAMP '2017-10-01') AND (vacols_hearsched.hearing_date ) < (TIMESTAMP '2018-09-09')))) AND ((((CASE
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
       IN ('Video', 'Central', 'Travel')))
GROUP BY 1,2,3,4
ORDER BY 5 DESC
LIMIT 30000

-- sql for creating the grand totals
SELECT 
	COUNT(*) AS "vacols_hearsched.hearing_result_count"
FROM vacols.hearsched  AS vacols_hearsched
LEFT JOIN vacols.staff  AS vacols_staff ON vacols_hearsched.board_member = vacols_staff.sattyid 

WHERE ((vacols_hearsched.board_member IS NOT NULL) AND (vacols_hearsched.board_member IS NOT NULL AND LENGTH(vacols_hearsched.board_member ) <> 0 )) AND ((((vacols_hearsched.hearing_date ) >= (TIMESTAMP '2017-10-01') AND (vacols_hearsched.hearing_date ) < (TIMESTAMP '2018-09-09')))) AND ((((CASE
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
       IN ('Video', 'Central', 'Travel')))
LIMIT 1