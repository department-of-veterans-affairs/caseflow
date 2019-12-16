-- raw sql results do not include filled-in values for 'vacols_decass.decomp_week'


WITH vacols_decass AS (select *, (select p.locdin from VACOLS.PRIORLOC p WHERE p.lockey=de.defolder AND p.locstto = '81' ORDER BY p.locdin DESC LIMIT 1) as distribution_date    from VACOLS.DECASS de )
SELECT * FROM (
SELECT *, DENSE_RANK() OVER (ORDER BY z___min_rank) as z___pivot_row_rank, RANK() OVER (PARTITION BY z__pivot_col_rank ORDER BY z___min_rank) as z__pivot_col_ordering FROM (
SELECT *, MIN(z___rank) OVER (PARTITION BY "vacols_staff.snamef","vacols_staff.snamel","vacols_decass.deatty") as z___min_rank FROM (
SELECT *, RANK() OVER (ORDER BY CASE WHEN z__pivot_col_rank=1 THEN 1 ELSE 2 END, CASE WHEN z__pivot_col_rank=1 THEN "vacols_decass.defolder_count" ELSE NULL END DESC NULLS LAST, "vacols_decass.defolder_count" DESC, z__pivot_col_rank, "vacols_staff.snamef", "vacols_staff.snamel", "vacols_decass.deatty") AS z___rank FROM (
SELECT *, DENSE_RANK() OVER (ORDER BY "vacols_decass.decomp_week" NULLS LAST) AS z__pivot_col_rank FROM (
SELECT 
	TO_CHAR(DATE_TRUNC('week', vacols_decass."DECOMP" ), 'YYYY-MM-DD') AS "vacols_decass.decomp_week",
	vacols_staff.snamef  AS "vacols_staff.snamef",
	vacols_staff.snamel  AS "vacols_staff.snamel",
	vacols_decass."DEATTY"  AS "vacols_decass.deatty",
	COUNT(*) AS "vacols_decass.defolder_count"
FROM vacols_decass
LEFT JOIN vacols.staff  AS vacols_staff ON (vacols_decass."DEATTY") = vacols_staff.sattyid 

WHERE ((((vacols_decass."DECOMP" ) >= (TIMESTAMP '2018-10-01') AND (vacols_decass."DECOMP" ) < (TIMESTAMP '2018-10-08')))) AND ((((vacols_decass."DEPROD") IS NOT NULL))) AND ((vacols_staff.sattyid  IN ('1826', '1258', '889', '1337', '1521', '1977')))
GROUP BY DATE_TRUNC('week', vacols_decass."DECOMP" ),2,3,4) ww
) bb WHERE z__pivot_col_rank <= 16384
) aa
) xx
) zz
 WHERE z___pivot_row_rank <= 500 OR z__pivot_col_ordering = 1 ORDER BY z___pivot_row_rank

-- sql for creating the pivot row totals
WITH vacols_decass AS (select *, (select p.locdin from VACOLS.PRIORLOC p WHERE p.lockey=de.defolder AND p.locstto = '81' ORDER BY p.locdin DESC LIMIT 1) as distribution_date    from VACOLS.DECASS de )
SELECT 
	vacols_staff.snamef  AS "vacols_staff.snamef",
	vacols_staff.snamel  AS "vacols_staff.snamel",
	vacols_decass."DEATTY"  AS "vacols_decass.deatty",
	COUNT(*) AS "vacols_decass.defolder_count"
FROM vacols_decass
LEFT JOIN vacols.staff  AS vacols_staff ON (vacols_decass."DEATTY") = vacols_staff.sattyid 

WHERE ((((vacols_decass."DECOMP" ) >= (TIMESTAMP '2018-10-01') AND (vacols_decass."DECOMP" ) < (TIMESTAMP '2018-10-08')))) AND ((((vacols_decass."DEPROD") IS NOT NULL))) AND ((vacols_staff.sattyid  IN ('1826', '1258', '889', '1337', '1521', '1977')))
GROUP BY 1,2,3
ORDER BY 4 DESC
LIMIT 30000