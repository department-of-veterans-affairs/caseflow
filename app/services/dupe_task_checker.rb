# frozen_string_literal: true

class DupeTaskChecker
  def initialize(appeal:)
    @appeal = appeal
  end

  def find_duplicate_tasks_for_type(task_type)
    open_tasks = @appeal.tasks.open.where(type: task_type)

    return open_tasks if open_tasks.count > 1

    nil
  end

  class << self
    def find_all_appeals_with_duplicate_tasks(task_model)
      find_legacy_appeals_with_duplicate_tasks(task_model) + find_appeals_with_duplicate_tasks(task_model)
    end

    def find_legacy_appeals_with_duplicate_tasks(task_model)
      find_appeals_with_duplicate_tasks_for_appeal_type(LegacyAppeal, task_model)
    end

    def find_appeals_with_duplicate_tasks(task_model)
      find_appeals_with_duplicate_tasks_for_appeal_type(Appeal, task_model)
    end

    def aggregate_duplicate_tasks
      aggregate_duplicate_tasks_for_appeal_type(Appeal) + aggregate_duplicate_tasks_for_appeal_type(LegacyAppeal)
    end

    private

    def find_appeals_with_duplicate_tasks_for_appeal_type(appeal_model, task_model)
      appeal_model.where("\
        id in (SELECT \
        appeal_id \
        FROM tasks \
        WHERE AND appeal_type=? AND type=? \
        AND status NOT IN ('completed', 'cancelled') \
        GROUP BY appeal_id \
        HAVING count(appeal_id) > 1)", appeal_model.name, task_model.name)
    end

    def aggregate_duplicate_tasks_for_appeal_type(appeal_model)
      appeal_model.joins(:tasks)
        .select("#{appeal_model.table_name}.id, COUNT(tasks.id) AS task_count, tasks.type AS task_type")
        .where("tasks.status NOT IN ('completed', 'cancelled')")
        .group("#{appeal_model.table_name}.id, task_type")
        .having("COUNT(tasks.id) > ?", 1)
        .map do |appeal|
          {
            appeal_id: appeal.id,
            appeal_type: appeal_model.name,
            task_type: appeal.task_type,
            task_count: appeal.task_count
          }
        end
    end
  end
end
