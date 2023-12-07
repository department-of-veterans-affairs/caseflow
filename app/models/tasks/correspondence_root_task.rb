class CorrespondenceRootTask < Task
  before_create :verify_org_task_unique

  def create_from_params(params, user)
    binding.pry
    parent_task = Task.find(params[:parent_id])
    fail Caseflow::Error::ChildTaskAssignedToSameUser if parent_of_same_type_has_same_assignee(parent_task, params)

    verify_user_can_create!(user, parent)

    params = modify_params_for_create(params)
    child = create_child_task(parent, user, params)
    parent_task.update!(status: params[:status]) if params[:status]
    child
  end

  def verify_user_can_create!(user, parent)
    binding.pry
    can_create = parent&.available_actions(user)&.map do |action|
      parent.build_action_hash(action, user)
    end
    # end&.any? do |action|
    #   action.dig(:data, :type) == name || action.dig(:data, :options)&.any? { |option| option.dig(:value) == name }

    # if !parent&.actions_allowable?(current_user) || !can_create
    #   user_description = current_user ? "User #{current_user.id}" : "nil User"
    #   parent_description = parent ? " from #{parent.class.name} #{parent.id}" : ""
    #   message = "#{user_description} cannot assign #{name}#{parent_description}."
    #   fail Caseflow::Error::ActionForbiddenError, message: message
    # end
    binding.pry
  end

  def create_child_task(parent_task, current_user, params)
    Task.create!(
      type: name,
      appeal: parent.appeal,
      assigned_by_id: child_assigned_by_id(parent_task, current_user),
      parent_id: parent.id,
      assigned_to: params[:assigned_to] || child_task_assignee(parent_task, params),
      instructions: params[:instructions]
    )
  end

  def available_actions(current_user)
    if assigned_to.users.include?(current_user)
      [
        Constants.TASK_ACTIONS.CORRESPONDENCE_REMOVE_PACKAGE.to_h
      ]
    end

    binding.pry
    [
      Constants.TASK_ACTIONS.CORRESPONDENCE_REMOVE_PACKAGE.to_h
    ]
  end

  private

  def verify_org_task_unique
    binding.pry
    if Task.where(
      appeal_id: appeal_id,
      appeal_type: "Correspondence",
      type: "correspondence_root_task"
    ).any?
      fail(
        Caseflow::Error::DuplicateOrgTask,
        task_type: self.class.name,
        assignee_type: assigned_to.class.name
      )
    end
  end
end
