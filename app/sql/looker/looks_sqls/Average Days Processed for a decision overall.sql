WITH average_time_for_decision AS (SELECT AVG(DATEDIFF(days, appeals.established_at, decision_documents.decision_date)) as average_time_for_decision
         from public.appeals as appeals
         left outer join public.decision_documents as decision_documents on appeals.id = decision_documents.appeal_id
      )
SELECT 
	average_time_for_decision.average_time_for_decision  AS "average_time_for_decision.average_time_for_decision"
FROM average_time_for_decision

GROUP BY 1
ORDER BY 1 
LIMIT 500