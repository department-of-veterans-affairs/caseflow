class AttorneyQueue < WorkQueue
  def self.tasks_with_appeals(user_id)
    binding.pry
    css_id = User.find(user_id).css_id
    vacols_tasks = repository.tasks_for_user(css_id)
    vacols_appeals = repository.appeals_from_tasks(vacols_tasks)

    tasks = vacols_tasks.map do |task|
      VacolsAssignment.from_vacols(task, user_id)
    end
    [tasks, vacols_appeals]
  end

  # We don't redefine the repository as a fake
  # on BaseQueue until after autoloading happens,
  # so if we rely on the autoloaded method we'll never
  # get the fake. Awwwkward.
  def self.repository
    WorkQueue.repository
  end
end
