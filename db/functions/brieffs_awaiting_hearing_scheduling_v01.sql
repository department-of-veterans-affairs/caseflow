CREATE OR REPLACE FUNCTION brieffs_awaiting_hearing_scheduling()
  RETURNS SETOF brieff_record
  LANGUAGE plpgsql AS
$func$
DECLARE
	legacy_case_ids text;
BEGIN
  SELECT *
  INTO legacy_case_ids
  FROM gather_vacols_ids_of_hearing_schedulable_legacy_appeals();


  RETURN QUERY
    EXECUTE format(
      'SELECT * FROM f_vacols_brieff WHERE bfkey IN (%s)',
      legacy_case_ids
    );
END $func$;
