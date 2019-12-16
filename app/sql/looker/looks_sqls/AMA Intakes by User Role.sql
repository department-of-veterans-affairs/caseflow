SELECT 
	TO_CHAR(DATE_TRUNC('month', intakes.completed_at ), 'YYYY-MM') AS "intakes.completed_month",
	users.roles  AS "users.roles",
	COUNT(*) AS "intakes.count"
FROM public.intakes  AS intakes
LEFT JOIN public.users  AS users ON intakes.user_id = users.id 

WHERE ((((intakes.completed_at ) >= ((DATE_TRUNC('month', DATE_TRUNC('day',GETDATE())))) AND (intakes.completed_at ) < ((DATEADD(month,1, DATE_TRUNC('month', DATE_TRUNC('day',GETDATE())) )))))) AND (intakes.completion_status = 'success') AND ((intakes.type  NOT IN ('RampElectionIntake', 'RampRefilingIntake') OR intakes.type IS NULL))
GROUP BY DATE_TRUNC('month', intakes.completed_at ),2
ORDER BY 1 DESC,3 DESC,2 
LIMIT 5000

-- sql for creating the total and/or determining pivot columns
SELECT 
	COUNT(*) AS "intakes.count"
FROM public.intakes  AS intakes
LEFT JOIN public.users  AS users ON intakes.user_id = users.id 

WHERE ((((intakes.completed_at ) >= ((DATE_TRUNC('month', DATE_TRUNC('day',GETDATE())))) AND (intakes.completed_at ) < ((DATEADD(month,1, DATE_TRUNC('month', DATE_TRUNC('day',GETDATE())) )))))) AND (intakes.completion_status = 'success') AND ((intakes.type  NOT IN ('RampElectionIntake', 'RampRefilingIntake') OR intakes.type IS NULL))
LIMIT 1