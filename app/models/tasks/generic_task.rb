class GenericTask < Task
  def allowed_actions(user)
    return [] if assigned_to != user && assigned_to_type != "Organization"

    [
      {
        label: "Assign to team",
        value: "modal/assign_to_team"
      },
      {
        label: "Assign to person",
        value: "modal/assign_to_person"
      },
      {
        label: "Mark task complete",
        value: "mark_task_complete"
      }
    ]
  end

  def update_from_params(params, current_user)
    verify_user_access(current_user)

    new_status = params[:status]
    if new_status == Constants.TASK_STATUSES.completed
      mark_as_complete!
    else
      update!(status: new_status)
    end
  end

  def can_user_access?(user)
    return true if assigned_to && assigned_to == user
    return true if user && assigned_to.is_a?(Organization) && assigned_to.user_has_access?(user)
    false
  end

  class << self
    def create_from_params(params_array, current_user)
      params_array.map do |params|
        parent = Task.find(params[:parent_id])
        fail Caseflow::Error::ChildTaskAssignedToSameUser if parent.assigned_to_id == params[:assigned_to_id] &&
                                                             parent.assigned_to_type == params[:assigned_to_type]

        parent.verify_user_access(current_user)

        child = create_child_task(parent, current_user, params)
        update_status(parent, params[:status])
        child
      end
    end

    private

    def create_child_task(parent, current_user, params)
      # Create an assignee from the input arguments so we throw an error if the assignee does not exist.
      assignee = Object.const_get(params[:assigned_to_type]).find(params[:assigned_to_id])

      parent.update!(status: :on_hold)

      GenericTask.create!(
        appeal: parent.appeal,
        assigned_by_id: child_assigned_by_id(parent, current_user),
        parent_id: parent.id,
        assigned_to: assignee
      )
    end

    def child_assigned_by_id(parent, current_user)
      return current_user.id if current_user
      return parent.assigned_to_id if parent && parent.assigned_to_type == User.name
    end

    def update_status(parent, status)
      return unless status

      case status
      when Constants.TASK_STATUSES.completed
        parent.mark_as_complete!
      else
        parent.update!(status: status)
      end
    end
  end
end
