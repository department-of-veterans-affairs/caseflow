# frozen_string_literal: true

class LegacyWorkQueue
  include ActiveModel::Model
  class << self
    def tasks_for_user(user)
      vacols_tasks = repository.tasks_for_user(user.css_id)
      tasks_from_vacols_tasks(vacols_tasks, user)
    end

    def tasks_by_appeal_id(appeal_id)
      vacols_tasks = repository.tasks_for_appeal(appeal_id)
      tasks_from_vacols_tasks(vacols_tasks)
    end

    def repository
      QueueRepository
    end

    private

    def tasks_from_vacols_tasks(vacols_tasks, user = nil)
      return [] if vacols_tasks.empty?

      vacols_appeals = repository.appeals_by_vacols_ids(vacols_tasks.map(&:vacols_id))

      vacols_tasks.zip(vacols_appeals).map do |task, appeal|
        user = validate_or_create_user(user, task.assigned_to_css_id)

        task_class = AttorneyLegacyTask
        # If the user is a pure_judge (not acting judge), they are only assigned JudgeLegacyTasks.
        # If the user is an acting judge, assume any case that already has a decision doc is assigned to them as a judge
        if user&.pure_judge_in_vacols? ||
           (user&.acting_judge_in_vacols? && appeal.assigned_to_acting_judge_as_judge?(user))
          task_class = JudgeLegacyTask
        end

        task_class.from_vacols(task, appeal, user)
      end
    end

    def validate_or_create_user(user, css_id)
      if css_id && (css_id == user&.css_id) && (user&.station_id == User::BOARD_STATION_ID)
        user
      elsif css_id
        User.find_by_css_id_or_create_with_default_station_id(css_id)
      end
    end
  end
end
