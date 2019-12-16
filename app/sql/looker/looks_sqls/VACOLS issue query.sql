WITH vacols_decass AS (select *, (select p.locdin from VACOLS.PRIORLOC p WHERE p.lockey=de.defolder AND p.locstto = '81' ORDER BY p.locdin DESC LIMIT 1) as distribution_date    from VACOLS.DECASS de )
SELECT * FROM (
SELECT *, DENSE_RANK() OVER (ORDER BY z___min_rank) as z___pivot_row_rank, RANK() OVER (PARTITION BY z__pivot_col_rank ORDER BY z___min_rank) as z__pivot_col_ordering FROM (
SELECT *, MIN(z___rank) OVER (PARTITION BY "vacols_decass.decomp_week","vacols_decass.deprod") as z___min_rank FROM (
SELECT *, RANK() OVER (ORDER BY "vacols_decass.decomp_week" DESC, z__pivot_col_rank, "vacols_decass.deprod") AS z___rank FROM (
SELECT *, DENSE_RANK() OVER (ORDER BY "vacols_decass.deatty" NULLS LAST) AS z__pivot_col_rank FROM (
SELECT 
	vacols_decass."DEATTY"  AS "vacols_decass.deatty",
	TO_CHAR(DATE_TRUNC('week', vacols_decass."DECOMP" ), 'YYYY-MM-DD') AS "vacols_decass.decomp_week",
	vacols_decass."DEPROD"  AS "vacols_decass.deprod",
	COUNT(*) AS "vacols_decass.defolder_count",
	(case when
            SUM(
                case when
                    vacols_issues.issdc = '5' OR
                    vacols_issues.issdc = '6' OR
                    vacols_issues.issdc = '8' OR
                    vacols_issues.issdc = '9'
                then 1 else null end
            ) > 0
        then 1 else 0 end
          +
          SUM(
            case when
                vacols_issues.issdc = '1' OR
                vacols_issues.issdc = '3' OR
                vacols_issues.issdc = '4'
            then 1 else 0 end
        )
      ) AS "vacols_issues.case_issue_count"
FROM vacols_decass
LEFT JOIN vacols.issues  AS vacols_issues ON (vacols_decass."DEFOLDER") = vacols_issues.isskey 

WHERE (((vacols_decass."DEATTY") = '1826')) AND ((((vacols_decass."DECOMP" ) >= (TIMESTAMP '2017-10-01') AND (vacols_decass."DECOMP" ) < (TIMESTAMP '2018-09-30')))) AND ((((vacols_decass."DEPROD") IS NOT NULL) AND (vacols_decass."DEPROD") NOT LIKE '%OT%'))
GROUP BY 1,DATE_TRUNC('week', vacols_decass."DECOMP" ),3) ww
) bb WHERE z__pivot_col_rank <= 16384
) aa
) xx
) zz
 WHERE z___pivot_row_rank <= 500 OR z__pivot_col_ordering = 1 ORDER BY z___pivot_row_rank