# Called "WorkQueue" instead of "Queue" to not conflict with the
# "Queue" class that ships with Ruby.
class WorkQueue
  include ActiveModel::Model
  class << self
    attr_writer :repository

    def tasks_with_appeals(user, role)
      vacols_tasks = repository.tasks_for_user(user.css_id)
      vacols_appeals = repository.appeals_from_tasks(vacols_tasks)

      tasks = vacols_tasks.map do |task|
        (role + "VacolsAssignment").constantize.from_vacols(task, user.id)
      end
      [tasks, vacols_appeals]
    end

    def repository
      QueueRepository if FeatureToggle.enabled?(:fakes_off)
      @repository ||= QueueRepository
    end
  end
end
