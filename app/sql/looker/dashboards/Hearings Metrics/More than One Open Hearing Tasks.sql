WITH appeals_with_open_hearing_tasks AS (SELECT appeals.id AS id, uuid AS external_id, closest_regional_office, 'Appeal' AS appeal_type,
    (
      SELECT count(child_tasks.id) FROM tasks AS child_tasks
      WHERE child_tasks.appeal_id = appeals.id AND child_tasks.appeal_type = appeal_type
      AND type IN ('HearingTask', 'ScheduleHearingTask', 'DispositionTask', 'ChangeDispositionTask')
      AND status IN ('assigned', 'on_hold', NULL)
    ) AS "total_open_tasks",
    (
      SELECT count(child_tasks.id) FROM tasks AS child_tasks
      WHERE child_tasks.appeal_id = appeals.id AND child_tasks.appeal_type = appeal_type
      AND status IN ('assigned', 'on_hold', NULL)
      AND type = 'HearingTask'
    ) AS "open_hearing_tasks",
    (
      SELECT count(child_tasks.id) FROM tasks AS child_tasks
      WHERE child_tasks.appeal_id = appeals.id AND child_tasks.appeal_type = appeal_type
      AND status IN ('assigned', 'on_hold', NULL)
      AND type = 'ScheduleHearingTask'
    ) AS "open_schedule_hearing_tasks",
    (
      SELECT count(child_tasks.id) FROM tasks AS child_tasks
      WHERE child_tasks.appeal_id = appeals.id AND child_tasks.appeal_type = appeal_type
      AND status IN ('assigned', 'on_hold', NULL)
      AND type = 'HearingTask'
    ) AS "open_disposition_tasks",
    (
      SELECT count(child_tasks.id) FROM tasks AS child_tasks
      WHERE child_tasks.appeal_id = appeals.id AND child_tasks.appeal_type = appeal_type
      AND status IN ('assigned', 'on_hold', NULL)
      AND type = 'ChangeDispositionTask'
    ) AS "open_change_disposition_tasks"
    FROM public.appeals WHERE total_open_tasks > 0
    UNION
    SELECT legacy_appeals.id AS id, vacols_id AS external_id, closest_regional_office, 'LegacyAppeal' AS appeal_type,
    (
      SELECT count(child_tasks.id) FROM tasks AS child_tasks
      WHERE child_tasks.appeal_id = legacy_appeals.id AND child_tasks.appeal_type = appeal_type
      AND status IN ('assigned', 'on_hold', NULL)
      AND type IN ('HearingTask', 'ScheduleHearingTask', 'DispositionTask', 'ChangeDispositionTask')
    ) AS "total_open_tasks",
    (
      SELECT count(child_tasks.id) FROM tasks AS child_tasks
      WHERE child_tasks.appeal_id = legacy_appeals.id AND child_tasks.appeal_type = appeal_type
      AND status IN ('assigned', 'on_hold', NULL)
      AND type = 'HearingTask'
    ) AS "open_hearing_tasks",
    (
      SELECT count(child_tasks.id) FROM tasks AS child_tasks
      WHERE child_tasks.appeal_id = legacy_appeals.id AND child_tasks.appeal_type = appeal_type
      AND status IN ('assigned', 'on_hold', NULL)
      AND type = 'ScheduleHearingTask'
    ) AS "open_schedule_hearing_tasks",
    (
      SELECT count(child_tasks.id) FROM tasks AS child_tasks
      WHERE child_tasks.appeal_id = legacy_appeals.id AND child_tasks.appeal_type = appeal_type
      AND status IN ('assigned', 'on_hold', NULL)
      AND type = 'HearingTask'
    ) AS "open_disposition_tasks",
    (
      SELECT count(child_tasks.id) FROM tasks AS child_tasks
      WHERE child_tasks.appeal_id = legacy_appeals.id AND child_tasks.appeal_type = appeal_type
      AND status IN ('assigned', 'on_hold', NULL)
      AND type = 'ChangeDispositionTask'
    ) AS "open_change_disposition_tasks"
    FROM public.legacy_appeals WHERE total_open_tasks > 0
             )
SELECT 
	appeals_with_open_hearing_tasks."appeal_type"  AS "appeals_with_open_hearing_tasks.appeal_type",
	appeals_with_open_hearing_tasks."id"  AS "appeals_with_open_hearing_tasks.id",
	appeals_with_open_hearing_tasks."open_hearing_tasks"  AS "appeals_with_open_hearing_tasks.open_hearing_tasks",
	appeals_with_open_hearing_tasks."open_schedule_hearing_tasks"  AS "appeals_with_open_hearing_tasks.open_schedule_hearing_tasks",
	appeals_with_open_hearing_tasks."open_disposition_tasks"  AS "appeals_with_open_hearing_tasks.open_disposition_tasks"
FROM appeals_with_open_hearing_tasks

WHERE 
	(appeals_with_open_hearing_tasks."open_hearing_tasks"  > 1)
GROUP BY 1,2,3,4,5
ORDER BY 3 
LIMIT 500