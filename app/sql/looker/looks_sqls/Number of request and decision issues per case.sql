SELECT 
	appeals.id  AS "appeals.id",
	COUNT(DISTINCT request_issues.id ) AS "request_issues.appeal_request_issue_count",
	COUNT(DISTINCT decision_issues.id ) AS "decision_issues.appeal_decision_issue_count"
FROM public.appeals  AS appeals
LEFT JOIN public.request_issues  AS request_issues ON appeals.id = request_issues.decision_review_id 
LEFT JOIN public.decision_issues  AS decision_issues ON appeals.id = decision_issues.decision_review_id AND decision_issues.decision_review_type = 'Appeal' 

GROUP BY 1
ORDER BY 3 DESC
LIMIT 500