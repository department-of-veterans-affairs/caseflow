class TaskHandler
  include ActiveModel::Model

  attr_accessor :current_role, :errors

  def create(task_params)
    action_type = task_params[:action_type]
    case action_type
    when :judge_case_assignment
      if role != "Judge"
        msg = "Only judge is allowed to create task with type: #{action_type}"
        return (errors || []) << msg
      end
      task = JudgeCaseAssignment.new(task_params).assign_to_attorney!
    else
      if role != "Attorney"
        msg = "Only attorney is allowed to create task with type: #{action_type}"
        return (errors || []) << msg
      end
      task = Task.create!(task_params)
    end
    task
  end
end
