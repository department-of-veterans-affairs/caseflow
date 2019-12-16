SELECT 
	to_char((DATE(appeals.receipt_date )), 'yymmdd') || '-' || appeals.id  AS "appeals.docket_number",
	appeals.uuid  AS "appeals.uuid",
	DATE(appeals.receipt_date ) AS "appeals.receipt_date",
	decision_issues.decision_review_type  AS "decision_issues.decision_review_type",
	decision_issues.disposition  AS "decision_issues.disposition"
FROM public.appeals  AS appeals
LEFT JOIN public.decision_issues  AS decision_issues ON appeals.id = decision_issues.decision_review_id AND decision_issues.decision_review_type = 'Appeal' 

WHERE ((((appeals.receipt_date ) >= (DATE(DATE '2018-08-06')) AND (appeals.receipt_date ) < (DATE(DATE '2018-12-05'))))) AND ((appeals.uuid  IN ('364bc6f9-1a1c-4e47-8938-821f9204b381', 'f12c115b-71b9-416a-af60-5493f66c65ae', '0137638d-a14b-4cbc-a6a1-ee5db13beb2a')))
GROUP BY 1,2,3,4,5
ORDER BY 3 DESC
LIMIT 2000