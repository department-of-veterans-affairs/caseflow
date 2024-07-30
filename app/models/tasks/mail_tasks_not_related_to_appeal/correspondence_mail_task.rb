# frozen_string_literal: true

# Abstract base class for "tasks not related to an appeal" added to a correspondence during Correspondence Intake.
class CorrespondenceMailTask < CorrespondenceTask
  self.abstract_class = true

  def self.create_child_task(parent, current_user, params)
    Task.create!(
      type: name,
      appeal: parent.appeal,
      appeal_type: Correspondence.name,
      assigned_by_id: child_assigned_by_id(parent, current_user),
      parent_id: parent.id,
      assigned_to: params[:assigned_to] || child_task_assignee(parent, params),
      instructions: params[:instructions]
    )
  end

  # this should have more guard clauses similar to available_actions in task.rb
  def available_actions(user)
    return [] unless user

    [
      Constants.TASK_ACTIONS.CANCEL_CORRESPONDENCE_TASK.to_h
    ]
  end
end
