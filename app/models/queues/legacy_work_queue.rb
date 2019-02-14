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

        task_class = (user&.vacols_roles&.first&.downcase == "judge") ? JudgeLegacyTask : AttorneyLegacyTask

        task_class.from_vacols(task, appeal, user)
      end
    end

    def validate_or_create_user(user, css_id)
      if css_id && (css_id == user&.css_id) && (user&.station_id == User::BOARD_STATION_ID)
        user
      elsif css_id
        User.find_or_create_by(css_id: css_id, station_id: User::BOARD_STATION_ID)
      end
    end
  end
end
