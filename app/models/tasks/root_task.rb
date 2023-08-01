# frozen_string_literal: true

##
# Caseflow Intake establishes the appeal. Once the appeal is established, Caseflow Queue automatically
# creates a Root Task for other tasks to attach to, depending on the Veteran's situation.
# Root task that tracks an appeal all the way through the appeal lifecycle.
# This task is closed when an appeal has been completely resolved.
# There should only be one RootTask per appeal.

class RootTask < Task
  before_create :verify_root_task_unique
  # Set assignee to the Bva organization automatically so we don't have to set it when we create RootTasks.
  after_initialize :set_assignee, if: -> { assigned_to_id.nil? }

  CHILD_TASK_TYPES_TO_CLOSE_AFTER_CLOSED = [TrackVeteranTask.name].freeze

  def set_assignee
    self.assigned_to = Bva.singleton
  end

  def when_child_task_completed(child_task)
    return unless child_task.post_dispatch_task?

    if all_open_children_will_be_closed_after_closed?
      completed!
    end
  end

  def self.creatable_tasks_types_when_on_hold
    [
      # Expect TrackVeteranTasks to occasionally be created for closed RootTasks because of timing complications
      # described in https://github.com/department-of-veterans-affairs/caseflow/issues/12574#issuecomment-549463832
      TrackVeteranTask.name
    ]
  end

  def self.allowed_creation_when_appeal_not_open(child_task)
    return true if creatable_tasks_types_when_on_hold.include?(child_task.type)

    # Expect mail to be received for dispatched or cancelled appeals.
    # CreateMailTaskDialog.jsx allows potentially all MailTask subclasses to be created
    # See `task_action_repository.rb: mail_assign_to_organization_data`
    return true if child_task.class < MailTask

    false
  end

  # Do not change the status of closed or on_hold RootTasks when child tasks are created for them.
  def when_child_task_created(child_task)
    if active?
      update!(status: :on_hold)
    elsif !on_hold? && !self.class.allowed_creation_when_appeal_not_open(child_task)
      Raven.capture_message("Created child task #{child_task&.type} #{child_task&.id} for RootTask #{id} " \
        "but did not update RootTask status. " \
        "If #{child_task&.type} is expected and #{status} RootTask does not require updating, " \
        "then add task type to RootTask.creatable_tasks_types_when_on_hold.")
    end
  end

  def update_children_status_after_closed
    transaction do
      # do not use update_all since that will avoid callbacks and we want versions history.
      children.open.where(type: CHILD_TASK_TYPES_TO_CLOSE_AFTER_CLOSED).find_each(&:completed!)
    end
  end

  def all_open_children_will_be_closed_after_closed?
    children.open.where.not(type: CHILD_TASK_TYPES_TO_CLOSE_AFTER_CLOSED).empty?
  end

  def hide_from_case_timeline
    true
  end

  def hide_from_task_snapshot
    true
  end

  def available_actions(user)
    return [Constants.TASK_ACTIONS.CREATE_MAIL_TASK.to_h] if RootTask.user_can_create_mail_task?(user)

    []
  end

  def self.user_can_create_mail_task?(user)
    user&.organizations&.any?(&:users_can_create_mail_task?)
  end

  def actions_available?(_user)
    true
  end

  def actions_allowable?(_user)
    true
  end

  def assigned_to_label
    COPY::CASE_LIST_TABLE_UNASSIGNED_LABEL
  end

  # Use the existence of a root task, active or inactive, to prevent duplicates
  # since there should only ever be one root task for a single appeal.
  def verify_root_task_unique
    if appeal.tasks.where(
      type: type
    ).any?
      fail(
        Caseflow::Error::DuplicateOrgTask,
        docket_number: appeal.docket_number,
        task_type: self.class.name,
        assignee_type: assigned_to.class.name
      )
    end
  end
end
