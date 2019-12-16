SELECT 
	appeals.veteran_file_number  AS "appeals.veteran_file_number",
	appeals.docket_type  AS "appeals.docket_type",
	to_char((DATE(appeals.receipt_date )), 'yymmdd') || '-' || appeals.id  AS "appeals.docket_number",
	DATE(decision_documents.decision_date ) AS "decision_documents.decision_date",
	DATE(decision_documents.uploaded_to_vbms_at ) AS "decision_documents.uploaded_to_vbms_date"
FROM public.tasks  AS tasks
LEFT JOIN public.appeals  AS appeals ON tasks.appeal_id = appeals.id AND tasks.appeal_type = 'Appeal'
LEFT JOIN public.decision_documents  AS decision_documents ON tasks.appeal_id = decision_documents.appeal_id

WHERE 
	(((decision_documents.uploaded_to_vbms_at ) >= (TIMESTAMP '2019-06-17') AND (decision_documents.uploaded_to_vbms_at ) < (TIMESTAMP '2019-06-24')))
GROUP BY 1,2,3,4,5
ORDER BY 4 DESC
LIMIT 2000