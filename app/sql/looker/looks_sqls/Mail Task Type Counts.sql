SELECT 
	tasks.type  AS "tasks.type",
	COUNT(DISTINCT tasks.id ) AS "tasks.count"
FROM public.tasks  AS tasks

WHERE 
	(tasks.type  IN ('EvidenceOrArgumentMailTask', 'ClearAndUnmistakeableErrorMailTask', 'HearingRelatedMailTask'))
GROUP BY 1
ORDER BY 2 DESC
LIMIT 500

-- sql for creating the total and/or determining pivot columns
SELECT 
	COUNT(DISTINCT tasks.id ) AS "tasks.count"
FROM public.tasks  AS tasks

WHERE 
	(tasks.type  IN ('EvidenceOrArgumentMailTask', 'ClearAndUnmistakeableErrorMailTask', 'HearingRelatedMailTask'))
LIMIT 1