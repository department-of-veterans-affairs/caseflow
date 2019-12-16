SELECT 
	tasks.appeal_id  AS "tasks.appeal_id"
FROM public.tasks  AS tasks
LEFT JOIN public.decision_issues  AS decision_issues ON tasks.appeal_id = decision_issues.decision_review_id

WHERE ((tasks.type = 'BvaDispatchTask') OR (tasks.type = 'QualityReviewTask')) AND decision_issues.id IS NULL
GROUP BY 1
ORDER BY 1 
LIMIT 500