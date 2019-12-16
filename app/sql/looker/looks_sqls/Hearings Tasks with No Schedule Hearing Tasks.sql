WITH hearing_tasks AS (SELECT
  tasks.id AS "tasks.id",
  tasks.type  AS "tasks.type",
  tasks.appeal_id  AS "tasks.appeal_id",
  tasks.appeal_type  AS "tasks.appeal_type",
  tasks.status AS "tasks.status",
  tasks.on_hold_duration AS "tasks.on_hold_duration",
  tasks.placed_on_hold_at AS "tasks.placed_on_hold_at",
  tasks.started_at AS "tasks.started_at",
  hearing_task_associations.id AS "hearing_task_associations.id",
  legacy_appeals.vacols_id AS "legacy_appeals.vacols_id",
  legacy_appeals.vbms_id AS "legacy_appeals.vbms_id",
  (case when tasks.appeal_type = 'Appeal' then appeals.uuid else legacy_appeals.vacols_id end) AS external_id,
  (case when tasks.appeal_type = 'Appeal' then appeals.closest_regional_office else legacy_appeals.closest_regional_office end)
    AS closest_regional_office,
  (
    SELECT count(child_tasks.id) FROM tasks AS child_tasks
    WHERE child_tasks.parent_id = tasks.id
  ) AS "count_of_child_tasks",
  (
    SELECT count(child_tasks.id) FROM tasks AS child_tasks
    WHERE child_tasks.parent_id = tasks.id AND
    child_tasks.type = 'ScheduleHearingTask'
  ) AS "schedule_hearing_tasks",
  (
    SELECT count(child_tasks.id) FROM tasks AS child_tasks
    WHERE child_tasks.parent_id = tasks.id AND
    child_tasks.type = 'DispositionTask'
  ) AS "disposition_tasks",
  (
    SELECT count(child_tasks.id) FROM tasks AS child_tasks
    WHERE child_tasks.parent_id = tasks.id AND
    child_tasks.type = 'ChangeDispositionTask'
  ) AS "change_disposition_tasks"
FROM public.tasks AS tasks
LEFT JOIN public.hearing_task_associations AS hearing_task_associations ON hearing_task_associations.hearing_task_id = tasks.id
LEFT JOIN public.hearings AS hearings ON hearing_task_associations.hearing_id = hearings.id
  AND tasks.appeal_type = 'Appeal'
LEFT JOIN public.legacy_hearings AS legacy_hearings ON hearing_task_associations.hearing_id = legacy_hearings.id
  AND tasks.appeal_type = 'LegacyAppeal'
LEFT JOIN public.appeals AS appeals ON tasks.appeal_id = appeals.id
  AND tasks.appeal_type = 'Appeal'
LEFT JOIN public.legacy_appeals AS legacy_appeals ON tasks.appeal_id = legacy_appeals.id
  AND tasks.appeal_type = 'LegacyAppeal'
WHERE
  (tasks.type = 'HearingTask')
GROUP BY 1,2,3,4,5,6,7,8,9,10,11,12,13
ORDER BY 1 DESC
       )
SELECT 
	hearing_tasks."tasks.appeal_id"  AS "hearing_tasks.tasks_appeal_id",
	hearing_tasks.closest_regional_office  AS "hearing_tasks.closest_regional_office",
	hearing_tasks."tasks.appeal_type"  AS "hearing_tasks.tasks_appeal_type",
	hearing_tasks.count_of_child_tasks  AS "hearing_tasks.count_of_child_tasks",
	hearing_tasks.disposition_tasks  AS "hearing_tasks.disposition_tasks",
	hearing_tasks.schedule_hearing_tasks  AS "hearing_tasks.schedule_hearing_tasks"
FROM hearing_tasks

WHERE 
	(hearing_tasks.schedule_hearing_tasks  = 0)
GROUP BY 1,2,3,4,5,6
ORDER BY 1 
LIMIT 500