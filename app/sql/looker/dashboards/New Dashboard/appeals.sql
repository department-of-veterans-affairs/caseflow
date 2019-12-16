SELECT * FROM (
SELECT *, DENSE_RANK() OVER (ORDER BY z___min_rank) as z___pivot_row_rank, RANK() OVER (PARTITION BY z__pivot_col_rank ORDER BY z___min_rank) as z__pivot_col_ordering FROM (
SELECT *, MIN(z___rank) OVER (PARTITION BY "decision_documents.bva_decision_dispatched","decision_issues.disposition_date") as z___min_rank FROM (
SELECT *, RANK() OVER (ORDER BY CASE WHEN z__pivot_col_rank=1 THEN 1 ELSE 2 END, CASE WHEN z__pivot_col_rank=1 THEN "appeals.count" ELSE NULL END DESC NULLS LAST, "appeals.count" DESC, z__pivot_col_rank, "decision_documents.bva_decision_dispatched", "decision_issues.disposition_date") AS z___rank FROM (
SELECT *, DENSE_RANK() OVER (ORDER BY "decision_issues.disposition" NULLS LAST, "tasks.status" NULLS LAST) AS z__pivot_col_rank FROM (
SELECT 
	decision_issues.disposition  AS "decision_issues.disposition",
	CASE tasks.status
          WHEN 'assigned' THEN '1_assigned'
          WHEN 'in_progress' THEN '2_viewed'
          WHEN 'on_hold' THEN '3_on_hold'
          WHEN 'completed' THEN '3_completed'
          ELSE tasks.status
         END
         AS "tasks.status",
	CASE WHEN decision_documents.citation_number IS NOT NULL   THEN 'Yes' ELSE 'No' END
 AS "decision_documents.bva_decision_dispatched",
	decision_issues.disposition_date  AS "decision_issues.disposition_date",
	COUNT(DISTINCT appeals.id ) AS "appeals.count"
FROM public.appeals  AS appeals
LEFT JOIN public.tasks  AS tasks ON tasks.appeal_id = appeals.id AND tasks.appeal_type = 'Appeal' 
LEFT JOIN public.decision_issues  AS decision_issues ON appeals.id = decision_issues.decision_review_id AND decision_issues.decision_review_type = 'Appeal' 
LEFT JOIN public.decision_documents  AS decision_documents ON decision_documents.appeal_id = appeals.id 

WHERE ((((decision_documents.decision_date ) >= ((DATE(DATEADD(month,-1, DATE_TRUNC('month', DATE_TRUNC('day',GETDATE())) )))) AND (decision_documents.decision_date ) < ((DATE(DATEADD(month,2, DATEADD(month,-1, DATE_TRUNC('month', DATE_TRUNC('day',GETDATE())) ) ))))))) AND ((((decision_documents.decision_date ) >= ((DATE(DATE_TRUNC('year', DATE_TRUNC('day',GETDATE()))))) AND (decision_documents.decision_date ) < ((DATE(DATEADD(year,1, DATE_TRUNC('year', DATE_TRUNC('day',GETDATE())) )))))))
GROUP BY 1,2,3,4) ww
) bb WHERE z__pivot_col_rank <= 16384
) aa
) xx
) zz
 WHERE z___pivot_row_rank <= 500 OR z__pivot_col_ordering = 1 ORDER BY z___pivot_row_rank