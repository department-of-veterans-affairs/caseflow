-- raw sql results do not include filled-in values for 'vacols_issues.issdcls_month'


SELECT * FROM (
SELECT *, DENSE_RANK() OVER (ORDER BY z___min_rank) as z___pivot_row_rank, RANK() OVER (PARTITION BY z__pivot_col_rank ORDER BY z___min_rank) as z__pivot_col_ordering FROM (
SELECT *, MIN(z___rank) OVER (PARTITION BY "vacols_issues.issdcls_month") as z___min_rank FROM (
SELECT *, RANK() OVER (ORDER BY "vacols_issues.issdcls_month" DESC, z__pivot_col_rank) AS z___rank FROM (
SELECT *, DENSE_RANK() OVER (ORDER BY "vacols_issues.issdc" DESC NULLS LAST) AS z__pivot_col_rank FROM (
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
	TO_CHAR(DATE_TRUNC('month', vacols_issues.issdcls ), 'YYYY-MM') AS "vacols_issues.issdcls_month",
	COUNT(*) AS "vacols_issues.issdc_count"
FROM vacols.issues  AS vacols_issues

WHERE (((CASE
        WHEN vacols_issues.issdc = '1' THEN 'Allowed'
        WHEN vacols_issues.issdc = '3' THEN 'Remanded'
        WHEN vacols_issues.issdc = '4' THEN 'Denied'
        WHEN vacols_issues.issdc = '5' THEN 'Vacated'
        WHEN vacols_issues.issdc = '6' THEN 'Dismissed, Withdrawn'
        WHEN vacols_issues.issdc = '8' THEN 'Dismissed, Death'
        ELSE vacols_issues.issdc
      END) LIKE '%1%' OR (CASE
        WHEN vacols_issues.issdc = '1' THEN 'Allowed'
        WHEN vacols_issues.issdc = '3' THEN 'Remanded'
        WHEN vacols_issues.issdc = '4' THEN 'Denied'
        WHEN vacols_issues.issdc = '5' THEN 'Vacated'
        WHEN vacols_issues.issdc = '6' THEN 'Dismissed, Withdrawn'
        WHEN vacols_issues.issdc = '8' THEN 'Dismissed, Death'
        ELSE vacols_issues.issdc
      END) LIKE '%2%' OR (CASE
        WHEN vacols_issues.issdc = '1' THEN 'Allowed'
        WHEN vacols_issues.issdc = '3' THEN 'Remanded'
        WHEN vacols_issues.issdc = '4' THEN 'Denied'
        WHEN vacols_issues.issdc = '5' THEN 'Vacated'
        WHEN vacols_issues.issdc = '6' THEN 'Dismissed, Withdrawn'
        WHEN vacols_issues.issdc = '8' THEN 'Dismissed, Death'
        ELSE vacols_issues.issdc
      END) LIKE '%3%' OR (CASE
        WHEN vacols_issues.issdc = '1' THEN 'Allowed'
        WHEN vacols_issues.issdc = '3' THEN 'Remanded'
        WHEN vacols_issues.issdc = '4' THEN 'Denied'
        WHEN vacols_issues.issdc = '5' THEN 'Vacated'
        WHEN vacols_issues.issdc = '6' THEN 'Dismissed, Withdrawn'
        WHEN vacols_issues.issdc = '8' THEN 'Dismissed, Death'
        ELSE vacols_issues.issdc
      END) LIKE '%4%' OR (CASE
        WHEN vacols_issues.issdc = '1' THEN 'Allowed'
        WHEN vacols_issues.issdc = '3' THEN 'Remanded'
        WHEN vacols_issues.issdc = '4' THEN 'Denied'
        WHEN vacols_issues.issdc = '5' THEN 'Vacated'
        WHEN vacols_issues.issdc = '6' THEN 'Dismissed, Withdrawn'
        WHEN vacols_issues.issdc = '8' THEN 'Dismissed, Death'
        ELSE vacols_issues.issdc
      END) LIKE '%5%' OR (CASE
        WHEN vacols_issues.issdc = '1' THEN 'Allowed'
        WHEN vacols_issues.issdc = '3' THEN 'Remanded'
        WHEN vacols_issues.issdc = '4' THEN 'Denied'
        WHEN vacols_issues.issdc = '5' THEN 'Vacated'
        WHEN vacols_issues.issdc = '6' THEN 'Dismissed, Withdrawn'
        WHEN vacols_issues.issdc = '8' THEN 'Dismissed, Death'
        ELSE vacols_issues.issdc
      END) LIKE '%6%' OR (CASE
        WHEN vacols_issues.issdc = '1' THEN 'Allowed'
        WHEN vacols_issues.issdc = '3' THEN 'Remanded'
        WHEN vacols_issues.issdc = '4' THEN 'Denied'
        WHEN vacols_issues.issdc = '5' THEN 'Vacated'
        WHEN vacols_issues.issdc = '6' THEN 'Dismissed, Withdrawn'
        WHEN vacols_issues.issdc = '8' THEN 'Dismissed, Death'
        ELSE vacols_issues.issdc
      END) LIKE '%7%' OR (CASE
        WHEN vacols_issues.issdc = '1' THEN 'Allowed'
        WHEN vacols_issues.issdc = '3' THEN 'Remanded'
        WHEN vacols_issues.issdc = '4' THEN 'Denied'
        WHEN vacols_issues.issdc = '5' THEN 'Vacated'
        WHEN vacols_issues.issdc = '6' THEN 'Dismissed, Withdrawn'
        WHEN vacols_issues.issdc = '8' THEN 'Dismissed, Death'
        ELSE vacols_issues.issdc
      END) LIKE '%8%' OR (CASE
        WHEN vacols_issues.issdc = '1' THEN 'Allowed'
        WHEN vacols_issues.issdc = '3' THEN 'Remanded'
        WHEN vacols_issues.issdc = '4' THEN 'Denied'
        WHEN vacols_issues.issdc = '5' THEN 'Vacated'
        WHEN vacols_issues.issdc = '6' THEN 'Dismissed, Withdrawn'
        WHEN vacols_issues.issdc = '8' THEN 'Dismissed, Death'
        ELSE vacols_issues.issdc
      END) LIKE '%9%')) AND ((((vacols_issues.issdcls ) >= (TIMESTAMP '2017-10-01') AND (vacols_issues.issdcls ) < (TIMESTAMP '2018-09-09'))))
GROUP BY 1,DATE_TRUNC('month', vacols_issues.issdcls )) ww
) bb WHERE z__pivot_col_rank <= 16384
) aa
) xx
) zz
 WHERE z___pivot_row_rank <= 500 OR z__pivot_col_ordering = 1 ORDER BY z___pivot_row_rank

-- sql for creating the total and/or determining pivot columns
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

WHERE (((CASE
        WHEN vacols_issues.issdc = '1' THEN 'Allowed'
        WHEN vacols_issues.issdc = '3' THEN 'Remanded'
        WHEN vacols_issues.issdc = '4' THEN 'Denied'
        WHEN vacols_issues.issdc = '5' THEN 'Vacated'
        WHEN vacols_issues.issdc = '6' THEN 'Dismissed, Withdrawn'
        WHEN vacols_issues.issdc = '8' THEN 'Dismissed, Death'
        ELSE vacols_issues.issdc
      END) LIKE '%1%' OR (CASE
        WHEN vacols_issues.issdc = '1' THEN 'Allowed'
        WHEN vacols_issues.issdc = '3' THEN 'Remanded'
        WHEN vacols_issues.issdc = '4' THEN 'Denied'
        WHEN vacols_issues.issdc = '5' THEN 'Vacated'
        WHEN vacols_issues.issdc = '6' THEN 'Dismissed, Withdrawn'
        WHEN vacols_issues.issdc = '8' THEN 'Dismissed, Death'
        ELSE vacols_issues.issdc
      END) LIKE '%2%' OR (CASE
        WHEN vacols_issues.issdc = '1' THEN 'Allowed'
        WHEN vacols_issues.issdc = '3' THEN 'Remanded'
        WHEN vacols_issues.issdc = '4' THEN 'Denied'
        WHEN vacols_issues.issdc = '5' THEN 'Vacated'
        WHEN vacols_issues.issdc = '6' THEN 'Dismissed, Withdrawn'
        WHEN vacols_issues.issdc = '8' THEN 'Dismissed, Death'
        ELSE vacols_issues.issdc
      END) LIKE '%3%' OR (CASE
        WHEN vacols_issues.issdc = '1' THEN 'Allowed'
        WHEN vacols_issues.issdc = '3' THEN 'Remanded'
        WHEN vacols_issues.issdc = '4' THEN 'Denied'
        WHEN vacols_issues.issdc = '5' THEN 'Vacated'
        WHEN vacols_issues.issdc = '6' THEN 'Dismissed, Withdrawn'
        WHEN vacols_issues.issdc = '8' THEN 'Dismissed, Death'
        ELSE vacols_issues.issdc
      END) LIKE '%4%' OR (CASE
        WHEN vacols_issues.issdc = '1' THEN 'Allowed'
        WHEN vacols_issues.issdc = '3' THEN 'Remanded'
        WHEN vacols_issues.issdc = '4' THEN 'Denied'
        WHEN vacols_issues.issdc = '5' THEN 'Vacated'
        WHEN vacols_issues.issdc = '6' THEN 'Dismissed, Withdrawn'
        WHEN vacols_issues.issdc = '8' THEN 'Dismissed, Death'
        ELSE vacols_issues.issdc
      END) LIKE '%5%' OR (CASE
        WHEN vacols_issues.issdc = '1' THEN 'Allowed'
        WHEN vacols_issues.issdc = '3' THEN 'Remanded'
        WHEN vacols_issues.issdc = '4' THEN 'Denied'
        WHEN vacols_issues.issdc = '5' THEN 'Vacated'
        WHEN vacols_issues.issdc = '6' THEN 'Dismissed, Withdrawn'
        WHEN vacols_issues.issdc = '8' THEN 'Dismissed, Death'
        ELSE vacols_issues.issdc
      END) LIKE '%6%' OR (CASE
        WHEN vacols_issues.issdc = '1' THEN 'Allowed'
        WHEN vacols_issues.issdc = '3' THEN 'Remanded'
        WHEN vacols_issues.issdc = '4' THEN 'Denied'
        WHEN vacols_issues.issdc = '5' THEN 'Vacated'
        WHEN vacols_issues.issdc = '6' THEN 'Dismissed, Withdrawn'
        WHEN vacols_issues.issdc = '8' THEN 'Dismissed, Death'
        ELSE vacols_issues.issdc
      END) LIKE '%7%' OR (CASE
        WHEN vacols_issues.issdc = '1' THEN 'Allowed'
        WHEN vacols_issues.issdc = '3' THEN 'Remanded'
        WHEN vacols_issues.issdc = '4' THEN 'Denied'
        WHEN vacols_issues.issdc = '5' THEN 'Vacated'
        WHEN vacols_issues.issdc = '6' THEN 'Dismissed, Withdrawn'
        WHEN vacols_issues.issdc = '8' THEN 'Dismissed, Death'
        ELSE vacols_issues.issdc
      END) LIKE '%8%' OR (CASE
        WHEN vacols_issues.issdc = '1' THEN 'Allowed'
        WHEN vacols_issues.issdc = '3' THEN 'Remanded'
        WHEN vacols_issues.issdc = '4' THEN 'Denied'
        WHEN vacols_issues.issdc = '5' THEN 'Vacated'
        WHEN vacols_issues.issdc = '6' THEN 'Dismissed, Withdrawn'
        WHEN vacols_issues.issdc = '8' THEN 'Dismissed, Death'
        ELSE vacols_issues.issdc
      END) LIKE '%9%')) AND ((((vacols_issues.issdcls ) >= (TIMESTAMP '2017-10-01') AND (vacols_issues.issdcls ) < (TIMESTAMP '2018-09-09'))))
GROUP BY 1
ORDER BY 1 DESC
LIMIT 500