# frozen_string_literal: true

##
# Root task that tracks an appeal all the way through the appeal lifecycle.
# This task is closed when an appeal has been completely resolved.

class RootTask < Task
  before_create :verify_root_task_unique
  # Set assignee to the Bva organization automatically so we don't have to set it when we create RootTasks.
  after_initialize :set_assignee, if: -> { assigned_to_id.nil? }

  def set_assignee
    self.assigned_to = Bva.singleton
  end

  def when_child_task_completed(_child_task); end

  # Do not change the status of closed or on_hold RootTasks when child tasks are created for them.
  def when_child_task_created(child_task)
    if active?
      update!(status: :on_hold)
    elsif !child_task.is_a?(TrackVeteranTask) && !on_hold?
      # Expect TrackVeteranTasks to occasionally be created for closed RootTasks because of timing complications
      # described in https://github.com/department-of-veterans-affairs/caseflow/issues/12574#issuecomment-549463832
      Raven.capture_message("Created child task for RootTask #{id} but did not update RootTask status")
    end
  end

  def update_children_status_after_closed
    children.open.where(type: TrackVeteranTask.name).update_all(status: Constants.TASK_STATUSES.completed)
  end

  def hide_from_case_timeline
    true
  end

  def hide_from_task_snapshot
    true
  end

  def available_actions(user)
    return [Constants.TASK_ACTIONS.CREATE_MAIL_TASK.to_h] if MailTeam.singleton.user_has_access?(user) && ama?

    []
  end

  def actions_available?(_user)
    true
  end

  def actions_allowable?(_user)
    true
  end

  def assigned_to_label
    COPY::CASE_LIST_TABLE_CASE_STORAGE_LABEL
  end

  # Use the existence of a root task, active or inactive, to prevent duplicates
  # since there should only ever be one root task for a single appeal.
  def verify_root_task_unique
    if appeal.tasks.where(
      type: type
    ).any?
      fail(
        Caseflow::Error::DuplicateOrgTask,
        appeal_id: appeal.id,
        task_type: self.class.name,
        assignee_type: assigned_to.class.name,
        parent_id: parent&.id
      )
    end
  end
end
