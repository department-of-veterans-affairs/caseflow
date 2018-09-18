class JudgeTask < Task
  validates :action, inclusion: { in: %w[assign review] }

  def self.create(params)
    super(params.merge(action: "assign"))
  end

  def when_child_task_completed
    update!(action: :review)
    super
  end

  def previous_task
    children_attorney_tasks = children.where(type: "AttorneyTask")
    fail Caseflow::Error::TooManyChildTasks, task_id: id if children_attorney_tasks.length > 1
    children_attorney_tasks[0]
  end
end
