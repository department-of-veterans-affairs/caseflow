# Called "WorkQueue" instead of "Queue" to not conflict with the
# "Queue" class that ships with Ruby.
class LegacyWorkQueue
  include ActiveModel::Model
  class << self
    def tasks_with_appeals(user, role)
      vacols_tasks = repository.tasks_for_user(user.css_id)
      tasks_with_appeals_of_vacols_tasks(user, role, vacols_tasks)
    end

    def tasks_with_appeals_by_appeal_id(appeal_id, role)
      vacols_tasks = repository.tasks_for_appeal(appeal_id)
      if vacols_tasks.empty?
        appeal = repository.appeals_by_vacols_ids([appeal_id])
        return [[], [appeal]]
      end
      assigned_to_css_id = vacols_tasks[0].assigned_to_css_id
      user = assigned_to_css_id &&
             User.find_or_create_by(css_id: assigned_to_css_id, station_id: User::BOARD_STATION_ID)
      tasks_with_appeals_of_vacols_tasks(user, role, vacols_tasks)
    end

    def repository
      QueueRepository
    end

    private

    MODEL_CLASS_OF_ROLE = {
      "Attorney" => AttorneyLegacyTask,
      "Judge" => JudgeLegacyTask
    }.freeze

    def tasks_with_appeals_of_vacols_tasks(user, role, vacols_tasks)
      vacols_appeals = repository.appeals_by_vacols_ids(vacols_tasks.map(&:vacols_id))

      tasks = vacols_tasks.zip(vacols_appeals).map do |task, appeal|
        MODEL_CLASS_OF_ROLE[role.capitalize].from_vacols(task, appeal, user)
      end
      [tasks, vacols_appeals]
    end
  end
end
