class AttorneyQueue < BaseQueue
  def self.tasks_with_appeals(user_id)
    css_id = User.find(user_id).css_id
    vacols_tasks = repository.tasks_for_user(css_id)
    vacols_appeals = repository.appeals_from_tasks(tasks)

    tasks = vacols_tasks.map do |task|
      DraftDecision.from_vacols(task, user_id)
    end
    [tasks, appeals]
  end

  # We don't redefine the repository as a fake
  # on BaseQueue until after autoloading happens,
  # so if we rely on the autoloaded method we'll never
  # get the fake. Awwwkward.
  def self.repository
    BaseQueue.repository
  end
end
