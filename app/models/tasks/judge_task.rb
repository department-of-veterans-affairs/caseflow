class JudgeTask < Task
  validates :action, inclusion: { in: %w[assign review] }

  def self.create(params)
    super(params.merge(action: "assign"))
  end
end
