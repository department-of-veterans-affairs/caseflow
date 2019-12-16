SELECT 
	appeals.docket_type  AS "appeals.docket_type",
	COUNT(DISTINCT CASE WHEN (advance_on_docket_motions.granted = 'true') THEN advance_on_docket_motions.id  ELSE NULL END) AS "advance_on_docket_motions.aod_count"
FROM public.people  AS people
LEFT JOIN public.claimants  AS claimants ON people.participant_id = claimants.participant_id 
INNER JOIN public.advance_on_docket_motions  AS advance_on_docket_motions ON people.id = advance_on_docket_motions.person_id
LEFT JOIN public.appeals  AS appeals ON claimants.decision_review_id = appeals.id AND claimants.decision_review_type = 'Appeal'

WHERE 
	(appeals.docket_type = 'hearing')
GROUP BY 1
ORDER BY 1 
LIMIT 500