class JudgeAssignTaskDistributor < RoundRobinTaskDistributor
  def initialize(list_of_assignees: Constants::RampJudges::USERS[Rails.current_env],
                 task_class: JudgeAssignTask)
    super
  end
end
