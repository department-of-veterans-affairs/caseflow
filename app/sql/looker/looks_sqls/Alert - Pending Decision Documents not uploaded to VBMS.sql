SELECT 
	decision_documents.id  AS "decision_documents.id",
	decision_documents.appeal_id  AS "decision_documents.appeal_id",
	DATE(decision_documents.uploaded_to_vbms_at ) AS "decision_documents.uploaded_to_vbms_date",
	DATE(decision_documents.submitted_at ) AS "decision_documents.submitted_date",
	DATE(decision_documents.processed_at ) AS "decision_documents.processed_date",
	DATE(decision_documents.attempted_at ) AS "decision_documents.attempted_date"
FROM public.appeals  AS appeals
LEFT JOIN public.decision_documents  AS decision_documents ON decision_documents.appeal_id = appeals.id 

WHERE ((decision_documents.submitted_at  < (DATEADD(day,-2, DATE_TRUNC('day',GETDATE()) )))) AND (decision_documents.processed_at  IS NULL)
GROUP BY 1,2,3,4,5,6
ORDER BY 3 DESC
LIMIT 500