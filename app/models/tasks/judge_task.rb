class JudgeTask < Task
  validates :action, inclusion: { in: %w[assign review] }

  before_create :set_action

  private

  def set_action
    self.action = :assign
  end
end
