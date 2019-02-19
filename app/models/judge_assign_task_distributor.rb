class JudgeAssignTaskDistributor < RoundRobinTaskDistributor
  def initialize(assignee_pool: Constants::RampJudges::USERS[Rails.current_env],
                 task_class: JudgeAssignTask)
    super
  end
end
