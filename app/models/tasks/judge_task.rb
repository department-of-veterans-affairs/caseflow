class JudgeTask < Task
  validates :action, inclusion: { in: %w[assign review] }

  def self.create(params)
    super(params.merge(action: "assign"))
  end

  def when_child_task_completed
    update!(status: :review)
    super
  end
end
