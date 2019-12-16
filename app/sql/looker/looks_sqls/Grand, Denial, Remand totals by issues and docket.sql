SELECT * FROM (
SELECT *, DENSE_RANK() OVER (ORDER BY z___min_rank) as z___pivot_row_rank, RANK() OVER (PARTITION BY z__pivot_col_rank ORDER BY z___min_rank) as z__pivot_col_ordering FROM (
SELECT *, MIN(z___rank) OVER (PARTITION BY "request_issues.disposition") as z___min_rank FROM (
SELECT *, RANK() OVER (ORDER BY CASE WHEN z__pivot_col_rank=1 THEN 1 ELSE 2 END, CASE WHEN z__pivot_col_rank=1 THEN "request_issues.appeal_request_issue_count" ELSE NULL END DESC NULLS LAST, "request_issues.appeal_request_issue_count" DESC, z__pivot_col_rank, "request_issues.disposition") AS z___rank FROM (
SELECT *, DENSE_RANK() OVER (ORDER BY "appeals.docket_type" NULLS LAST) AS z__pivot_col_rank FROM (
SELECT 
	appeals.docket_type  AS "appeals.docket_type",
	request_issues.disposition  AS "request_issues.disposition",
	COUNT(request_issues.id ) AS "request_issues.appeal_request_issue_count"
FROM public.appeals  AS appeals
LEFT JOIN public.request_issues  AS request_issues ON appeals.id = request_issues.decision_review_id 

GROUP BY 1,2) ww
) bb WHERE z__pivot_col_rank <= 16384
) aa
) xx
) zz
 WHERE z___pivot_row_rank <= 500 OR z__pivot_col_ordering = 1 ORDER BY z___pivot_row_rank