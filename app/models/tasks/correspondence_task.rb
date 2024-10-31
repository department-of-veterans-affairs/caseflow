# frozen_string_literal: true

class CorrespondenceTask < Task
  belongs_to :correspondence, class_name: "Correspondence", foreign_key: "appeal_id"
  self.abstract_class = true

  before_create :verify_org_task_unique
  belongs_to :appeal, class_name: "Correspondence"
  validate :status_is_valid_on_create, on: :create
  validate :assignee_status_is_valid_on_create, on: :create

  scope :package_action_tasks, -> { where(type: package_action_task_names) }

  delegate :nod, to: :correspondence

  class << self
    def create_from_params(params, user)
      # verify the user can create correspondence tasks
      verify_correspondence_access(user)

      parent_task = Task.find(params[:parent_id])
      fail Caseflow::Error::ChildTaskAssignedToSameUser if parent_of_same_type_has_same_assignee(parent_task, params)

      verify_user_can_create!(user, parent_task)

      params = modify_params_for_create(params)
      child = create_child_task(parent_task, user, params)
      parent_task.update!(status: params[:status]) if params[:status]
      child
    end

    private

    # block users from creating correspondence tasks if they are not members of Inbound Ops Team
    # ignore check if there is no current user on correspondence creation
    def verify_correspondence_access(user)
      fail Caseflow::Error::ActionForbiddenError, message: "User does not belong to Inbound Ops Team" unless
      InboundOpsTeam.singleton.user_has_access?(user) || user&.system_user?
    end
  end

  def self.package_action_task_names
    [
      ReassignPackageTask.name,
      RemovePackageTask.name,
      SplitPackageTask.name,
      MergePackageTask.name
    ]
  end

  def verify_org_task_unique
    if Task.where(
      appeal_id: appeal_id,
      appeal_type: appeal_type,
      type: type
    ).open.any?
      fail(
        Caseflow::Error::DuplicateOrgTask,
        task_type: self.class.name,
        assignee_type: assigned_to.class.name
      )
    end
  end

  def verify_no_other_open_package_action_task_on_correspondence
    return true unless package_action_task?

    if CorrespondenceTask.package_action_tasks.open.where(appeal_id: appeal_id).any?
      fail Caseflow::Error::MultipleOpenTasksOfSameTypeError, task_type: "package action task"
    end
  end

  def remove_package
    root_task = CorrespondenceRootTask.find_by!(
      appeal_id: @correspondence.id,
      assigned_to: InboundOpsTeam.singleton,
      appeal_type: "Correspondence",
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
    Correspondence.find(appeal_id)
  end

  def completed_by_date
    closed_at
  end

  def task_url
    # Future: route to the Correspondence Details Page after implementation.
    if ENV["RAILS_ENV"] == "production"
      "/under_construction"
    else
      "/explain/correspondence/#{correspondence.uuid}/"
    end
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

  def package_action_task?
    self.class.package_action_task_names.include?(self.class.name)
  end
end
