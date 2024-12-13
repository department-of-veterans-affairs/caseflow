CREATE OR REPLACE FUNCTION gather_vacols_ids_of_hearing_schedulable_legacy_appeals()
  RETURNS TEXT
  LANGUAGE plpgsql AS
$func$
DECLARE
	legacy_case_ids text;
BEGIN
	SELECT string_agg(DISTINCT format($$'%s'$$, vacols_id), ',')
	INTO legacy_case_ids
	FROM legacy_appeals
	JOIN tasks ON tasks.appeal_type = 'LegacyAppeal' and tasks.appeal_id = legacy_appeals.id
	WHERE
	  tasks.type = 'ScheduleHearingTask'
	  AND tasks.status IN ('assigned', 'in_progress', 'on_hold')
	GROUP BY tasks.type;

	RETURN legacy_case_ids;
END
$func$;
