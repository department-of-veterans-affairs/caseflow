# frozen_string_literal: true

class CorrespondenceTask < Task
  before_create :verify_org_task_unique
  validate :status_is_valid_on_create, on: :create
  validate :assignee_status_is_valid_on_create, on: :create

  def verify_org_task_unique
    if Task.where(
      appeal_id: appeal_id,
      appeal_type: appeal_type,
      type: type
    ).any?
      fail(
        Caseflow::Error::DuplicateOrgTask,
        task_type: self.class.name,
        assignee_type: assigned_to.class.name
      )
    end
  end

  def remove_package
    root_task = CorrespondenceRootTask.find_by!(
      appeal_id: @correspondence.id,
      assigned_to: MailTeamSupervisor.singleton,
      appeal_type: "Correspondence",
      parent_id: @correspondence_task.id,
      type: "CorrespondenceRootTask"
    )
    root_task.cancel_task_and_child_subtasks
  end

  def self.create_child_task(parent_task, current_user, params)
    Task.create!(
      type: params[:type],
      appeal_type: "Correspondence",
      appeal: parent_task.appeal,
      assigned_by_id: child_assigned_by_id(parent_task, current_user),
      parent_id: parent_task.id,
      assigned_to: params[:assigned_to] || child_task_assignee(parent_task, params),
      instructions: params[:instructions]
    )
  end

  def correspondence
    appeal
  end

  private

  # rubocop:disable Metrics/CyclomaticComplexity
  def status_is_valid_on_create
    case type
    when "ReviewPackageTask"
      return Constants.TASK_STATUSES.on_hold if status != Constants.TASK_STATUSES.on_hold
    when "CorrespondenceIntakeTask", "EfolderUploadFailedTask"
      return Constants.TASK_STATUSES.in_progress if status != Constants.TASK_STATUSES.in_progress
    when "CorrespondenceRootTask", "HearingPostponementRequestMailTask"
      return Constants.TASK_STATUSES.completed if status != Constants.TASK_STATUSES.completed
    else
      fail Caseflow::Error::InvalidStatusOnTaskCreate, task_type: type unless status == Constants.TASK_STATUSES.assigned
    end
    true
  end
  # rubocop:enable Metrics/CyclomaticComplexity

  def assignee_status_is_valid_on_create
    if parent&.child_must_have_active_assignee? && assigned_to.is_a?(User) && !assigned_to.active?
      fail Caseflow::Error::InvalidAssigneeStatusOnTaskCreate, assignee: assigned_to
    end

    true
  end
end
