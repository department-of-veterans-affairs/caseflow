-- Returns records from the VACOLS DB's CORRES table that are associated with
--   legacy cases in the National Hearing Queue.

CREATE OR REPLACE FUNCTION corres_awaiting_hearing_scheduling()
  RETURNS SETOF corres_record
  LANGUAGE plpgsql AS
$func$
DECLARE
	correspondent_ids TEXT;
BEGIN
  SELECT *
  INTO correspondent_ids
  FROM gather_bfcorkeys_of_hearing_schedulable_legacy_cases();

  if correspondent_ids IS NOT NULL THEN
    RETURN QUERY
      EXECUTE format(
        'SELECT * FROM f_vacols_corres WHERE stafkey IN (%s)',
        correspondent_ids
      );
  END IF;

  -- Force a null row return
  RETURN QUERY EXECUTE 'SELECT * FROM f_vacols_corres WHERE 1 = 0';
END $func$;
