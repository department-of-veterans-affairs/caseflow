WITH request_issues_by_previous_adjudication AS (SELECT distinct request_issue.id AS request_issue_id, request_issue.disposition, election.option_selected
      FROM ramp_issues refiling_issue, ramp_issues source_issue, ramp_elections election, ramp_refilings refiling, appeals appeal, request_issues request_issue
      WHERE
      refiling_issue.source_issue_id = source_issue.id AND
      refiling_issue.review_type = 'RampRefiling' AND
      refiling_issue.review_id = refiling.id AND
      refiling.option_selected = 'appeal' AND
      source_issue.review_type = 'RampElection' AND
      source_issue.review_id = election.id AND
      refiling.veteran_file_number = appeal.veteran_file_number AND
      request_issue.review_request_id = appeal.id
       )
SELECT 
	request_issues_by_previous_adjudication.option_selected  AS "request_issues_by_previous_adjudication.previous_adjudication",
	request_issues_by_previous_adjudication.disposition  AS "request_issues_by_previous_adjudication.disposition",
	COUNT(*) AS "request_issues_by_previous_adjudication.count"
FROM public.request_issues  AS request_issues
LEFT JOIN request_issues_by_previous_adjudication ON request_issues.id = request_issues_by_previous_adjudication.request_issue_id 

GROUP BY 1,2
ORDER BY 1 DESC
LIMIT 500

-- sql for creating the total and/or determining pivot columns
WITH request_issues_by_previous_adjudication AS (SELECT distinct request_issue.id AS request_issue_id, request_issue.disposition, election.option_selected
      FROM ramp_issues refiling_issue, ramp_issues source_issue, ramp_elections election, ramp_refilings refiling, appeals appeal, request_issues request_issue
      WHERE
      refiling_issue.source_issue_id = source_issue.id AND
      refiling_issue.review_type = 'RampRefiling' AND
      refiling_issue.review_id = refiling.id AND
      refiling.option_selected = 'appeal' AND
      source_issue.review_type = 'RampElection' AND
      source_issue.review_id = election.id AND
      refiling.veteran_file_number = appeal.veteran_file_number AND
      request_issue.review_request_id = appeal.id
       )
SELECT 
	COUNT(*) AS "request_issues_by_previous_adjudication.count"
FROM public.request_issues  AS request_issues
LEFT JOIN request_issues_by_previous_adjudication ON request_issues.id = request_issues_by_previous_adjudication.request_issue_id 

LIMIT 1