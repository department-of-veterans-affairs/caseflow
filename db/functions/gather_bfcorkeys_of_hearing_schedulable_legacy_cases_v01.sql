CREATE OR REPLACE FUNCTION gather_bfcorkeys_of_hearing_schedulable_legacy_cases()
  RETURNS TEXT
  LANGUAGE plpgsql AS
$func$
DECLARE
	bfcorkey_ids TEXT;
BEGIN
	SELECT string_agg(DISTINCT format($$'%s'$$, bfcorkey), ',')
	INTO bfcorkey_ids
	FROM brieffs_awaiting_hearing_scheduling();

	RETURN bfcorkey_ids;
END
$func$;
