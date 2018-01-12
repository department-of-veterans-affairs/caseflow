class AttorneyQueue < BaseQueue
  def self.tasks(user_id)
    css_id = User.find(user_id).css_id
    tasks = repository.tasks_for_user(css_id)
    appeals = repository.appeals_from_tasks(tasks)



    tasks.map do |task|
      appeal = appeals.find { |appeal| appeal.vacols_id == task.vacols_id }
      DraftDecision.from_vacols(task, appeal, user_id)
    end
  end

  # We don't redefine the repository as a fake
  # on BaseQueue until after autoloading happens,
  # so if we rely on the autoloaded method we'll never
  # get the fake. Awwwkward.
  def self.repository
    BaseQueue.repository
  end
end
