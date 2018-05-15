class TaskHandler
  include ActiveModel::Model

  attr_accessor :current_role, :errors

  def create(task_params)
    case task_params[:action_type]
    when :judge_case_assignment
      return (errors || []) << "Only judge is allowed to create task with type: #{task_params[:action_type]}" if role != "Judge"
      task = JudgeCaseAssignment.new(task_params).assign_to_attorney!
    else
      return (errors || []) << "Only attorney is allowed to create task with type: #{task_params[:action_type]}" if role != "Attorney"
      task = Task.create!(task_params)
    end
    task
  end
end