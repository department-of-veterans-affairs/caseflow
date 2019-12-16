SELECT 
	appeals.docket_type  AS "appeals.docket_type",
	COUNT(DISTINCT appeals.id ) AS "appeals.count"
FROM public.appeals  AS appeals
LEFT JOIN public.decision_documents  AS decision_documents ON decision_documents.appeal_id = appeals.id 

WHERE (decision_documents.citation_number IS NOT NULL) AND ((((decision_documents.decision_date ) >= (DATE(DATE '2019-06-01')) AND (decision_documents.decision_date ) < (DATE(DATE '2019-06-30')))))
GROUP BY 1
ORDER BY 2 DESC
LIMIT 500

-- sql for creating the total and/or determining pivot columns
SELECT 
	COUNT(DISTINCT appeals.id ) AS "appeals.count"
FROM public.appeals  AS appeals
LEFT JOIN public.decision_documents  AS decision_documents ON decision_documents.appeal_id = appeals.id 

WHERE (decision_documents.citation_number IS NOT NULL) AND ((((decision_documents.decision_date ) >= (DATE(DATE '2019-06-01')) AND (decision_documents.decision_date ) < (DATE(DATE '2019-06-30')))))
LIMIT 1