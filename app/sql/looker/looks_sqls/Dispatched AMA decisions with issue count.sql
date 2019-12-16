SELECT 
	COUNT(DISTINCT CASE WHEN decision_documents.citation_number IS NOT NULL   THEN decision_documents.id  ELSE NULL END) AS "decision_documents.bva_decision_dispatched_count",
	COUNT(DISTINCT decision_issues.id ) AS "decision_issues.appeal_decision_issue_count"
FROM public.appeals  AS appeals
LEFT JOIN public.decision_issues  AS decision_issues ON appeals.id = decision_issues.decision_review_id AND decision_issues.decision_review_type = 'Appeal' 
LEFT JOIN public.decision_documents  AS decision_documents ON decision_documents.appeal_id = appeals.id 

WHERE 
	decision_documents.citation_number IS NOT NULL  
LIMIT 500