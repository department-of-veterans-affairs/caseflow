-- Returns records from the VACOLS DB's REP table that are associated with
--   legacy cases in the National Hearing Queue.

CREATE OR REPLACE FUNCTION rep_awaiting_hearing_scheduling()
  RETURNS SETOF rep_record
  LANGUAGE plpgsql AS
$func$
DECLARE
	legacy_case_ids text;
BEGIN
  SELECT *
  INTO legacy_case_ids
  FROM gather_vacols_ids_of_hearing_schedulable_legacy_appeals();

  if legacy_case_ids IS NOT NULL THEN
    RETURN QUERY
      EXECUTE format(
        'SELECT * FROM f_vacols_rep WHERE repkey IN (%s)',
        legacy_case_ids
      );
  END IF;

  -- Force a null row return
  RETURN QUERY EXECUTE 'SELECT * FROM f_vacols_rep WHERE 1 = 0';
END $func$;
