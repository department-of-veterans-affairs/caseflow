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
    CAST(appeals.stream_docket_number AS CHAR) AS docket_number
FROM appeals
JOIN tasks ON tasks.appeal_type = 'Appeal' and tasks.appeal_id = appeals.id
WHERE tasks.type = 'ScheduleHearingTask'
  and tasks.status IN ('assigned', 'in_progress', 'on_hold')

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
    f_vacols_folder.tinum AS docket_number
FROM legacy_appeals
JOIN tasks ON tasks.appeal_type = 'Appeal' and tasks.appeal_id = legacy_appeals.id
JOIN f_vacols_brieff ON (legacy_appeals.vacols_id = f_vacols_brieff.bfkey)
JOIN f_vacols_folder ON (f_vacols_brieff.bfkey = f_vacols_folder.ticknum)
WHERE tasks.type = 'ScheduleHearingTask'
  and tasks.status IN ('assigned', 'in_progress', 'on_hold')
