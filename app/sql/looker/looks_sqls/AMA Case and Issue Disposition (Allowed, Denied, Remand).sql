SELECT * FROM (
SELECT *, DENSE_RANK() OVER (ORDER BY z___min_rank) as z___pivot_row_rank, RANK() OVER (PARTITION BY z__pivot_col_rank ORDER BY z___min_rank) as z__pivot_col_ordering FROM (
SELECT *, MIN(z___rank) OVER (PARTITION BY "decision_documents.bva_decision_dispatched","appeals.docket_type") as z___min_rank FROM (
SELECT *, RANK() OVER (ORDER BY CASE WHEN z__pivot_col_rank=1 THEN 1 ELSE 2 END, CASE WHEN z__pivot_col_rank=1 THEN "decision_documents.count" ELSE NULL END DESC NULLS LAST, "decision_documents.count" DESC, z__pivot_col_rank, "decision_documents.bva_decision_dispatched", "appeals.docket_type") AS z___rank FROM (
SELECT *, DENSE_RANK() OVER (ORDER BY "decision_issues.disposition" NULLS LAST) AS z__pivot_col_rank FROM (
SELECT 
	decision_issues.disposition  AS "decision_issues.disposition",
	CASE WHEN decision_documents.citation_number IS NOT NULL   THEN 'Yes' ELSE 'No' END
 AS "decision_documents.bva_decision_dispatched",
	appeals.docket_type  AS "appeals.docket_type",
	COUNT(DISTINCT decision_documents.id ) AS "decision_documents.count",
	COUNT(DISTINCT decision_issues.id ) AS "decision_issues.appeal_decision_issue_count"
FROM public.appeals  AS appeals
LEFT JOIN public.decision_issues  AS decision_issues ON appeals.id = decision_issues.decision_review_id AND decision_issues.decision_review_type = 'Appeal' 
LEFT JOIN public.decision_documents  AS decision_documents ON decision_documents.appeal_id = appeals.id 

WHERE 
	decision_documents.citation_number IS NOT NULL  
GROUP BY 1,2,3) ww
) bb WHERE z__pivot_col_rank <= 16384
) aa
) xx
) zz
 WHERE z___pivot_row_rank <= 500 OR z__pivot_col_ordering = 1 ORDER BY z___pivot_row_rank

-- sql for creating the total and/or determining pivot columns
SELECT 
	decision_issues.disposition  AS "decision_issues.disposition",
	COUNT(DISTINCT decision_documents.id ) AS "decision_documents.count",
	COUNT(DISTINCT decision_issues.id ) AS "decision_issues.appeal_decision_issue_count"
FROM public.appeals  AS appeals
LEFT JOIN public.decision_issues  AS decision_issues ON appeals.id = decision_issues.decision_review_id AND decision_issues.decision_review_type = 'Appeal' 
LEFT JOIN public.decision_documents  AS decision_documents ON decision_documents.appeal_id = appeals.id 

WHERE 
	decision_documents.citation_number IS NOT NULL  
GROUP BY 1
ORDER BY 1 
LIMIT 500

-- sql for creating the pivot row totals
SELECT 
	CASE WHEN decision_documents.citation_number IS NOT NULL   THEN 'Yes' ELSE 'No' END
 AS "decision_documents.bva_decision_dispatched",
	appeals.docket_type  AS "appeals.docket_type",
	COUNT(DISTINCT decision_documents.id ) AS "decision_documents.count",
	COUNT(DISTINCT decision_issues.id ) AS "decision_issues.appeal_decision_issue_count"
FROM public.appeals  AS appeals
LEFT JOIN public.decision_issues  AS decision_issues ON appeals.id = decision_issues.decision_review_id AND decision_issues.decision_review_type = 'Appeal' 
LEFT JOIN public.decision_documents  AS decision_documents ON decision_documents.appeal_id = appeals.id 

WHERE 
	decision_documents.citation_number IS NOT NULL  
GROUP BY 1,2
ORDER BY 3 DESC
LIMIT 30000

-- sql for creating the grand totals
SELECT 
	COUNT(DISTINCT decision_documents.id ) AS "decision_documents.count",
	COUNT(DISTINCT decision_issues.id ) AS "decision_issues.appeal_decision_issue_count"
FROM public.appeals  AS appeals
LEFT JOIN public.decision_issues  AS decision_issues ON appeals.id = decision_issues.decision_review_id AND decision_issues.decision_review_type = 'Appeal' 
LEFT JOIN public.decision_documents  AS decision_documents ON decision_documents.appeal_id = appeals.id 

WHERE 
	decision_documents.citation_number IS NOT NULL  
LIMIT 1