WITH
    latest_cutoff_date AS (
        SELECT cutoff_date
        FROM schedulable_cutoff_dates
        ORDER BY created_at DESC
        LIMIT 1
    )

SELECT
  appeals.id AS appeal_id,
  'Appeal' AS appeal_type,
  -- COALESCE selects the first non-null value
  COALESCE(
    appeals.changed_hearing_request_type,
    appeals.original_hearing_request_type
  ) AS hearing_request_type,
  REPLACE (CAST(appeals.receipt_date AS TEXT), '-', '') AS receipt_date,
  CAST(appeals.uuid AS TEXT) AS external_id,
  CAST(appeals.stream_type AS TEXT) AS appeal_stream,
  CAST(appeals.stream_docket_number AS TEXT) AS docket_number,
  CASE
    WHEN appeals.aod_based_on_age = TRUE
      OR advance_on_docket_motions.granted = TRUE
      OR veteran_person.date_of_birth <= CURRENT_DATE - INTERVAL '75 years'
      OR aod_based_on_age_recognized_claimants.quantity > 0
    THEN TRUE
    ELSE FALSE
  END AS aod_indicator,
  tasks.id AS task_id,
  tasks.assigned_to_id AS assigned_to_id,
  tasks.assigned_to_type AS assigned_to_type,
  tasks.assigned_at AS assigned_at,
  tasks.assigned_by_id AS assigned_by_id,
  CASE
  	WHEN tasks.status = 'on_hold' THEN CURRENT_DATE - tasks.placed_on_hold_at::date
  	ELSE null
  END AS days_on_hold,
  COALESCE(tasks.closed_at::date, CURRENT_DATE) - tasks.assigned_at::date AS days_waiting,
  tasks.status AS task_status,
  CASE
    WHEN stream_type = 'court_remand'
     OR (
	     CASE
	    	WHEN appeals.aod_based_on_age = TRUE
		      OR advance_on_docket_motions.granted = TRUE
		      OR veteran_person.date_of_birth <= CURRENT_DATE - INTERVAL '75 years'
		      OR aod_based_on_age_recognized_claimants.quantity > 0
	    	THEN TRUE
	    	ELSE FALSE
  		END
     ) IS TRUE
     OR receipt_date <= COALESCE((SELECT cutoff_date FROM latest_cutoff_date),'2019-12-31')
    THEN TRUE
    ELSE FALSE
  END AS schedulable,
  veterans.state_of_residence,
  veterans.country_of_residence,
  cached_appeal_attributes.suggested_hearing_location,
  CASE
    WHEN (request_issues_status.aggregate_mst_status = true) THEN true
    ELSE false
  END AS mst_indicator,
  CASE
    WHEN (request_issues_status.aggregate_pact_status = true) THEN true
    ELSE false
  END AS pact_indicator
FROM
  appeals
  JOIN tasks ON tasks.appeal_type = 'Appeal'
  AND tasks.appeal_id = appeals.id
  LEFT JOIN advance_on_docket_motions ON advance_on_docket_motions.appeal_id = appeals.id
  JOIN veterans ON appeals.veteran_file_number = veterans.file_number
  LEFT JOIN people veteran_person ON veteran_person.participant_id = veterans.participant_id
  LEFT JOIN LATERAL (
    SELECT count(*) as quantity
    FROM claimants
    JOIN people ON claimants.participant_id = people.participant_id
    WHERE claimants.decision_review_id = appeals.id
      AND claimants.decision_review_type = 'Appeal'
      AND people.date_of_birth <= CURRENT_DATE - INTERVAL '75 years'
  ) aod_based_on_age_recognized_claimants ON TRUE
  LEFT JOIN cached_appeal_attributes ON (
    cached_appeal_attributes.appeal_id = appeals.id AND cached_appeal_attributes.appeal_type = 'Appeal'
  )
  LEFT JOIN (
    SELECT decision_review_id, bool_or(mst_status) AS aggregate_mst_status, bool_or(pact_status) AS aggregate_pact_status
    FROM request_issues
    WHERE decision_review_type = 'Appeal'
    GROUP BY decision_review_id
  ) AS request_issues_status ON (appeals.id = request_issues_status.decision_review_id)
WHERE
  tasks.type = 'ScheduleHearingTask'
  AND tasks.status IN ('assigned', 'in_progress', 'on_hold')

-- Union for legacy appeals equivalent of above
UNION

SELECT
  legacy_appeals.id AS appeal_id,
  'LegacyAppeal' AS appeal_type,
  f_vacols_brieff.bfhr AS hearing_request_type,
  REPLACE (CAST(f_vacols_brieff.bfd19 AS TEXT), '-', '') AS receipt_date,
  f_vacols_brieff.bfkey AS external_id,
  CASE
    WHEN f_vacols_brieff.bfac = '1' THEN 'Original'
    WHEN f_vacols_brieff.bfac = '2' THEN 'Supplemental'
    WHEN f_vacols_brieff.bfac = '3' THEN 'Post Remand'
    WHEN f_vacols_brieff.bfac = '4' THEN 'Reconsideration'
    WHEN f_vacols_brieff.bfac = '5' THEN 'Vacate'
    WHEN f_vacols_brieff.bfac = '6' THEN 'De Novo'
    WHEN f_vacols_brieff.bfac = '7' THEN 'Court Remand'
    WHEN f_vacols_brieff.bfac = '8' THEN 'Designation of Record'
    WHEN f_vacols_brieff.bfac = '9' THEN 'Clear and Unmistakable Error'
  END AS appeal_stream,
  f_vacols_folder.tinum AS docket_number,
  CASE
    WHEN (
      f_vacols_corres.sspare2 IS NULL
      AND f_vacols_corres.sdob <= (CURRENT_DATE - INTERVAL '75 years')
    )
      -- This could be either the Veteran or a non-Veteran claimant
      OR people.date_of_birth <= (CURRENT_DATE - INTERVAL '75 years') THEN TRUE
    WHEN f_vacols_assign.tskactcd IN ('B', 'B1', 'B2') THEN TRUE
    ELSE FALSE
  END AS aod_indicator,
  tasks.id AS task_id,
  tasks.assigned_to_id AS assigned_to_id,
  tasks.assigned_to_type AS assigned_to_type,
  tasks.assigned_at AS assigned_at,
  tasks.assigned_by_id AS assigned_by_id,
  CASE
  	WHEN tasks.status = 'on_hold' THEN CURRENT_DATE - tasks.placed_on_hold_at::date
  	ELSE null
  END AS days_on_hold,
  COALESCE(tasks.closed_at::date, CURRENT_DATE) - tasks.assigned_at::date AS days_waiting,
  tasks.status AS task_status,
  TRUE as schedulable,
  veterans.state_of_residence,
  veterans.country_of_residence,
  cached_appeal_attributes.suggested_hearing_location,
  CASE
    WHEN fvi.mst = 'Y' THEN TRUE
    ELSE false
  END AS mst_indicator,
  CASE
    WHEN fvi.pact = 'Y' then true
    ELSE false
  END AS pact_indicator
FROM
  legacy_appeals
  JOIN tasks ON tasks.appeal_type = 'LegacyAppeal'
  AND tasks.appeal_id = legacy_appeals.id
  JOIN f_vacols_brieff ON (legacy_appeals.vacols_id = f_vacols_brieff.bfkey)
  JOIN f_vacols_folder ON (f_vacols_brieff.bfkey = f_vacols_folder.ticknum)
  LEFT JOIN f_vacols_assign ON (f_vacols_assign.tsktknm = f_vacols_brieff.bfkey)
  LEFT JOIN f_vacols_corres ON (
    f_vacols_brieff.bfcorkey = f_vacols_corres.stafkey
  )
  LEFT JOIN people ON (f_vacols_corres.ssn = people.ssn)
  JOIN veterans ON veterans.ssn = f_vacols_corres.ssn
  LEFT JOIN cached_appeal_attributes ON (
    cached_appeal_attributes.appeal_id = legacy_appeals.id AND cached_appeal_attributes.appeal_type = 'LegacyAppeal'
  )
  LEFT JOIN (SELECT isskey,
    MAX(issmst) AS mst,
    MAX(isspact) AS pact
    FROM f_vacols_issues
    GROUP BY isskey) AS fvi ON (fvi.isskey = f_vacols_brieff.bfkey)
WHERE
  tasks.type = 'ScheduleHearingTask'
  AND tasks.status IN ('assigned', 'in_progress', 'on_hold')
