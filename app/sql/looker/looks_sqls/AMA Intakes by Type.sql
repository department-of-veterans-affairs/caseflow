-- raw sql results do not include filled-in values for 'intakes.completed_month'


SELECT * FROM (
SELECT *, DENSE_RANK() OVER (ORDER BY z___min_rank) as z___pivot_row_rank, RANK() OVER (PARTITION BY z__pivot_col_rank ORDER BY z___min_rank) as z__pivot_col_ordering FROM (
SELECT *, MIN(z___rank) OVER (PARTITION BY "intakes.completed_month") as z___min_rank FROM (
SELECT *, RANK() OVER (ORDER BY "intakes.completed_month" DESC, CASE WHEN z__pivot_col_rank=1 THEN 1 ELSE 2 END, CASE WHEN z__pivot_col_rank=1 THEN "intakes.count" ELSE NULL END DESC NULLS LAST, "intakes.count" DESC, z__pivot_col_rank) AS z___rank FROM (
SELECT *, DENSE_RANK() OVER (ORDER BY "intakes.type" NULLS LAST) AS z__pivot_col_rank FROM (
SELECT 
	intakes.type  AS "intakes.type",
	TO_CHAR(DATE_TRUNC('month', intakes.completed_at ), 'YYYY-MM') AS "intakes.completed_month",
	COUNT(*) AS "intakes.count"
FROM public.intakes  AS intakes

WHERE ((((intakes.completed_at ) >= ((DATEADD(month,-2, DATE_TRUNC('month', DATE_TRUNC('day',GETDATE())) ))) AND (intakes.completed_at ) < ((DATEADD(month,3, DATEADD(month,-2, DATE_TRUNC('month', DATE_TRUNC('day',GETDATE())) ) )))))) AND (intakes.completion_status = 'success') AND ((intakes.type  IN ('HigherLevelReviewIntake', 'SupplementalClaimIntake', 'AppealIntake')))
GROUP BY 1,DATE_TRUNC('month', intakes.completed_at )) ww
) bb WHERE z__pivot_col_rank <= 16384
) aa
) xx
) zz
 WHERE z___pivot_row_rank <= 5000 OR z__pivot_col_ordering = 1 ORDER BY z___pivot_row_rank

-- sql for creating the total and/or determining pivot columns
SELECT 
	intakes.type  AS "intakes.type",
	COUNT(*) AS "intakes.count"
FROM public.intakes  AS intakes

WHERE ((((intakes.completed_at ) >= ((DATEADD(month,-2, DATE_TRUNC('month', DATE_TRUNC('day',GETDATE())) ))) AND (intakes.completed_at ) < ((DATEADD(month,3, DATEADD(month,-2, DATE_TRUNC('month', DATE_TRUNC('day',GETDATE())) ) )))))) AND (intakes.completion_status = 'success') AND ((intakes.type  IN ('HigherLevelReviewIntake', 'SupplementalClaimIntake', 'AppealIntake')))
GROUP BY 1
ORDER BY 1 
LIMIT 5000