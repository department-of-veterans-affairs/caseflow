# frozen_string_literal: true

class CorrespondenceTask < Task
  belongs_to :correspondence, foreign_type: "Correspondence", foreign_key: "appeal_id", polymorphic: true
  self.abstract_class = true

  before_create :verify_org_task_unique
  belongs_to :appeal, class_name: "Correspondence"
  validate :status_is_valid_on_create, on: :create
  validate :assignee_status_is_valid_on_create, on: :create

  scope :package_action_tasks, -> { where(type: package_action_task_names) }
  scope :tasks_not_related_to_an_appeal, -> { where(type: tasks_not_related_to_an_appeal_names) }
  scope :correspondence_mail_tasks, -> { where(type: correspondence_mail_task_names) }
  scope :efolder_parent_tasks, -> { where(id: where(type: EfolderUploadFailedTask.name).active.pluck(:parent_id)) }

  # scopes to handle task queue logic
  # Correspondence Cases queries
  scope :unassigned_tasks, -> { where(type: ReviewPackageTask.name, status: Constants.TASK_STATUSES.unassigned) }
  # due to 'on_hold' tasks also getting action_required_tasks, join efolder parent task
  scope :assigned_tasks, lambda {
                           where(type: active_task_names).active.or(efolder_parent_tasks)
                         }
  scope :action_required_tasks, -> { where(assigned_to: InboundOpsTeam.singleton).package_action_tasks.active }
  scope :pending_tasks, -> { tasks_not_related_to_an_appeal.open }
  # a correspondence is completed if the root task is completed or there are no active child tasks
  # since active child tasks set the root task status to 'on_hold', the assumption is if a root task isn't on hold or
  # cancelled, the correspondence is completed.
  # This assumption is used to lower the N+1 query checking all the child task statuses.
  scope :completed_root_tasks, lambda {
                                 where(type: CorrespondenceRootTask.name).where.not(
                                   status: Constants.TASK_STATUSES.on_hold
                                 ).where.not(status: Constants.TASK_STATUSES.cancelled)
                               }

  # Your Correspondence queries
  scope :user_assigned_tasks, lambda { |assignee|
    where(type: active_task_names).open.where("assigned_to_id=?", assignee&.id)
  }

  scope :user_in_progress_tasks, lambda { |assignee|
    where("assigned_to_id=?", assignee&.id)
      .where.not(type: EfolderUploadFailedTask.name)
      .where(status: [Constants.TASK_STATUSES.in_progress, Constants.TASK_STATUSES.on_hold])
  }

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

  def self.active_task_names
    [
      CorrespondenceIntakeTask.name,
      ReviewPackageTask.name
    ].freeze
  end

  def self.package_action_task_names
    [
      ReassignPackageTask.name,
      RemovePackageTask.name,
      SplitPackageTask.name,
      MergePackageTask.name
    ].freeze
  end

  def self.tasks_not_related_to_an_appeal_names
    [
      CavcCorrespondenceCorrespondenceTask.name,
      CongressionalInterestCorrespondenceTask.name,
      DeathCertificateCorrespondenceTask.name,
      FoiaRequestCorrespondenceTask.name,
      OtherMotionCorrespondenceTask.name,
      PowerOfAttorneyRelatedCorrespondenceTask.name,
      PrivacyActRequestCorrespondenceTask.name,
      PrivacyComplaintCorrespondenceTask.name,
      StatusInquiryCorrespondenceTask.name,
      ReturnToInboundOpsTask.name
    ].freeze
  end

  def self.correspondence_mail_task_names
    [
      AssociatedWithClaimsFolderMailTask.name,
      AddressChangeCorrespondenceMailTask.name,
      EvidenceOrArgumentCorrespondenceMailTask.name,
      VacolsUpdatedMailTask.name
    ].freeze
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
    # route to the Correspondence Details Page.
    if !FeatureToggle.enabled?(:correspondence_queue)
      "/under_construction"
    else
      Constants.CORRESPONDENCE_TASK_URL.CORRESPONDENCE_TASK_DETAIL_URL.sub("uuid", correspondence.uuid)
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
