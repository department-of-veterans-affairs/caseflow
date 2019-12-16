SELECT 
	decision_issues.disposition  AS "decision_issues.disposition",
	to_char((DATE(appeals.receipt_date )), 'yymmdd') || '-' || appeals.id  AS "appeals.docket_number",
	COUNT(DISTINCT appeals.id ) AS "appeals.count",
	COUNT(DISTINCT decision_issues.id ) AS "decision_issues.appeal_decision_issue_count"
FROM public.appeals  AS appeals
LEFT JOIN public.decision_issues  AS decision_issues ON appeals.id = decision_issues.decision_review_id AND decision_issues.decision_review_type = 'Appeal' 
LEFT JOIN public.decision_documents  AS decision_documents ON decision_documents.appeal_id = appeals.id 

WHERE (appeals.established_at  IS NOT NULL) AND (decision_documents.decision_date  IS NOT NULL)
GROUP BY 1,2
HAVING (NOT (COUNT(DISTINCT appeals.id ) = 0)) AND (NOT (COUNT(DISTINCT decision_issues.id ) = 0))
ORDER BY 2 DESC
LIMIT 500

-- sql for creating the total and/or determining pivot columns
SELECT 
	COUNT(DISTINCT appeals.id ) AS "appeals.count",
	COUNT(DISTINCT decision_issues.id ) AS "decision_issues.appeal_decision_issue_count"
FROM public.appeals  AS appeals
LEFT JOIN public.decision_issues  AS decision_issues ON appeals.id = decision_issues.decision_review_id AND decision_issues.decision_review_type = 'Appeal' 
LEFT JOIN public.decision_documents  AS decision_documents ON decision_documents.appeal_id = appeals.id 

WHERE (appeals.established_at  IS NOT NULL) AND (decision_documents.decision_date  IS NOT NULL)
HAVING (NOT (COUNT(DISTINCT appeals.id ) = 0)) AND (NOT (COUNT(DISTINCT decision_issues.id ) = 0))
LIMIT 1