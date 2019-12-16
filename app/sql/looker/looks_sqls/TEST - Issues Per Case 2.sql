SELECT 
	appeals.docket_type  AS "appeals.docket_type",
	decision_issues.disposition  AS "decision_issues.disposition",
	COUNT(DISTINCT appeals.id ) AS "appeals.count",
	COUNT(decision_issues.id ) AS "decision_issues.count",
	COUNT(decision_issues.id ) AS "decision_issues.appeal_decision_issue_count"
FROM public.appeals  AS appeals
LEFT JOIN public.decision_issues  AS decision_issues ON appeals.id = decision_issues.decision_review_id AND decision_issues.decision_review_type = 'Appeal' 

WHERE 
	(appeals.established_at  IS NOT NULL)
GROUP BY 1,2
ORDER BY 3 DESC
LIMIT 500

-- sql for creating the total and/or determining pivot columns
SELECT 
	COUNT(DISTINCT appeals.id ) AS "appeals.count",
	COUNT(decision_issues.id ) AS "decision_issues.count",
	COUNT(decision_issues.id ) AS "decision_issues.appeal_decision_issue_count"
FROM public.appeals  AS appeals
LEFT JOIN public.decision_issues  AS decision_issues ON appeals.id = decision_issues.decision_review_id AND decision_issues.decision_review_type = 'Appeal' 

WHERE 
	(appeals.established_at  IS NOT NULL)
LIMIT 1