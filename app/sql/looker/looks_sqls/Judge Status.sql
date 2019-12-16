SELECT 
	judge_case_reviews.judge_id  AS "judge_case_reviews.judge_id",
	users.full_name  AS "users.full_name",
	tasks.appeal_id  AS "tasks.appeal_id",
	COUNT(*) AS "judge_case_reviews.count",
	COUNT(DISTINCT appeals.id ) AS "appeals.count"
FROM public.judge_case_reviews  AS judge_case_reviews
LEFT JOIN public.tasks  AS tasks ON judge_case_reviews.task_id = tasks.id 
LEFT JOIN public.appeals  AS appeals ON tasks.appeal_id = appeals.id 
LEFT JOIN public.users  AS users ON judge_case_reviews.judge_id = users.id 

GROUP BY 1,2,3
ORDER BY 5 DESC
LIMIT 500