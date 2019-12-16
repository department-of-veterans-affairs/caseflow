SELECT 
	CASE WHEN decision_documents.citation_number IS NOT NULL   THEN 'Yes' ELSE 'No' END
 AS "decision_documents.bva_decision_dispatched",
	COUNT(decision_documents.id ) AS "decision_documents.count"
FROM public.appeals  AS appeals
LEFT JOIN public.decision_documents  AS decision_documents ON decision_documents.appeal_id = appeals.id 

WHERE 
	decision_documents.citation_number IS NOT NULL  
GROUP BY 1
ORDER BY 2 DESC
LIMIT 500