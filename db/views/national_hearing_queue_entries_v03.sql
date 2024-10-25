--- this view is a way to see both of the appeals and legacy appeals information IN a single table
--- materialized means that this information will be cached IN a temporary table
SELECT
    appeals.id AS appeal_id,
    'Appeal' AS appeal_type,
    -- COALESCE selects the first non-null value
    COALESCE(appeals.changed_hearing_request_type, appeals.original_hearing_request_type) AS hearing_request_type,
    CAST(appeals.receipt_date AS CHAR) AS receipt_date,
    CAST(appeals.uuid AS CHAR) AS external_id,
    CAST(appeals.stream_type AS CHAR) AS appeal_stream,
    CAST(appeals.stream_docket_number AS CHAR) AS docket_number,
    case
	    when appeals.aod_based_on_age = true or advance_on_docket_motions.granted = true or people.date_of_birth >= current_date - INTERVAL '75 years' then 'true'
	    else 'false'
	end as aod_indicator
FROM appeals
JOIN tasks ON tasks.appeal_type = 'Appeal' and tasks.appeal_id = appeals.id
JOIN advance_on_docket_motions ON advance_on_docket_motions.appeal_id = appeals.id
JOIN veterans on appeals.veteran_file_number = veterans.file_number
JOIN people on people.participant_id = veterans.participant_id
WHERE tasks.type = 'ScheduleHearingTask'
  and tasks.status IN ('assigned', 'in_progress', 'on_hold')

  -- TODO: LegacyAppeals query needs further testing and is not fully complete
  -- Union for legacy appeals equivalent of above
UNION

SELECT
    legacy_appeals.id AS appeal_id,
    'LegacyAppeal' AS appeal_type,
    f_vacols_brieff.bfhr AS hearing_request_type,
    REPLACE(CAST(f_vacols_brieff.bfd19 AS CHAR), '-', '') AS receipt_date,
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
      WHEN f_vacols_brieff.bfac = '9' THEN 'Clear and Unmistakeable Error'
    END AS appeal_stream,
    f_vacols_folder.tinum AS docket_number,
    case
      when f_vacols_corres.sspare2 = null and (f_vacols_corres.sdob >= current_date - interval '75 years' or people.date_of_birth >= current_date - interval '75 years') then true
      when f_vacols_assign.tskactcd in ('B', 'B1', 'B2') then true
      else false
    end as aod_indicator

FROM legacy_appeals
JOIN tasks ON tasks.appeal_type = 'LegacyAppeal' and tasks.appeal_id = legacy_appeals.id
JOIN f_vacols_brieff ON (legacy_appeals.vacols_id = f_vacols_brieff.bfkey)
JOIN f_vacols_folder ON (f_vacols_brieff.bfkey = f_vacols_folder.ticknum)
join f_vacols_assign on (f_vacols_assign.tsktknm = f_vacols_brieff.bfkey)
join f_vacols_corres on (f_vacols_brieff.bfcorkey = f_vacols_corres.stafkey)
join people on (f_vacols_corres.ssn = people.ssn)
WHERE tasks.type = 'ScheduleHearingTask'
  and tasks.status IN ('assigned', 'in_progress', 'on_hold')

