# Called "WorkQueue" instead of "Queue" to not conflict with the
# "Queue" class that ships with Ruby.
class LegacyWorkQueue
  include ActiveModel::Model
  class << self
    attr_writer :repository

    def tasks_with_appeals(user, role)
      vacols_tasks = repository.tasks_for_user(user.css_id)
      tasks_with_appeals_of_vacols_tasks(user, role, vacols_tasks)
    end

    def tasks_with_appeals_of_appeal(appeal_id)
      vacols_tasks = repository.tasks_for_appeal(appeal_id)
      # Look up user and their role
      tasks_with_appeals_of_vacols_tasks(user, role, vacols_tasks)
    end

    def repository
      return QueueRepository if FeatureToggle.enabled?(:test_facols)
      @repository ||= QueueRepository
    end
  private
    def tasks_with_appeals_of_vacols_tasks(user, role, vacols_tasks)
      vacols_appeals = repository.appeals_from_tasks(vacols_tasks)

      tasks = vacols_tasks.zip(vacols_appeals).map do |task, appeal|
        (role.capitalize + "LegacyTask").constantize.from_vacols(task, appeal, user)
      end
      [tasks, vacols_appeals]
    end
  end
end
