# frozen_string_literal: true

##
# Task to track when the mail team receives any appeal-related mail from an appellant.
# Mail is processed by a mail team member, and then a corresponding task is then assigned to an organization.
# Tasks are assigned to organizations, including VLJ Support, AOD team, Privacy team, and Lit Support, and include:
#   - add Evidence or Argument
#   - changing Power of Attorney
#   - advance a case on docket (AOD)
#   - withdrawing an appeal
#   - switching dockets
#   - add post-decision motions
# Adding a mail task to an appeal is done by mail team members and will create a task assigned to the mail team. It
# will also automatically create a child task assigned to the team the task should be routed to.

class MailTask < Task
  # Skip unique verification for mail tasks since multiple mail tasks of each type can be created.
  def verify_org_task_unique; end

  class << self
    def blocking?
      # Some open mail tasks should block distribution of an appeal to judges.
      # Define this method in subclasses for blocking task types.
      false
    end

    def subclass_routing_options(user: nil, appeal: nil)
      filtered = MailTask.subclasses.select { |sc| sc.allow_creation?(user: user, appeal: appeal) }
      sorted = filtered.sort_by(&:label).map { |subclass| { value: subclass.name, label: subclass.label } }
      if !FeatureToggle.enabled?(:cavc_remand, user: user)
        sorted.reject { |task| task[:label] == CavcCorrespondenceMailTask.label }
      else
        sorted
      end
    end

    def allow_creation?(_user = nil, _appeal = nil)
      true
    end

    def parent_if_blocking_task(parent_task)
      if blocking? && !parent_task.appeal.distributed_to_a_judge?
        return parent_task.appeal.tasks.find_by(type: DistributionTask.name)
      end

      parent_task
    end

    def create_from_params(params, user)
      parent_task = Task.find(params[:parent_id])

      verify_user_can_create!(user, parent_task)

      transaction do
        if parent_task.is_a?(RootTask)
          # Create a task assigned to the mail team with a child task so we can track how that child was created.
          parent_task = create!(
            appeal: parent_task.appeal,
            parent_id: parent_if_blocking_task(parent_task).id,
            assigned_to: MailTeam.singleton,
            instructions: [params[:instructions]].flatten
          )
        end

        if child_task_assignee(parent_task, params).eql? MailTeam.singleton
          parent_task
        else
          params = modify_params_for_create(params)
          create_child_task(parent_task, user, params)
        end
      end
    end

    def child_task_assignee(parent, params)
      if [:assigned_to_type, :assigned_to_id].all? { |key| params.key?(key) }
        super
      else
        default_assignee(parent)
      end
    end

    def pending_hearing_task?(parent)
      parent.appeal.tasks.open.any? { |task| task.is_a?(HearingTask) }
    end

    def case_active?(parent)
      parent.appeal.active?
    end

    def most_recent_active_task_assignee(parent)
      parent.appeal.tasks.open.where(assigned_to_type: User.name).order(:created_at).last&.assigned_to
    end
  end

  def hide_from_task_snapshot
    super || (assigned_to.eql?(MailTeam.singleton) && !active?)
  end

  def blocking?
    self.class.blocking?
  end

  def available_actions(user)
    super(user).present? ? super(user).unshift(Constants.TASK_ACTIONS.CHANGE_TASK_TYPE.to_h) : []
  end

  def create_twin_of_type(params)
    task_type = Object.const_get(params[:type])
    parent_task = task_type.create!(
      appeal: appeal,
      parent: parent,
      assigned_by: assigned_by,
      assigned_to: MailTeam.singleton
    )

    task_type.create!(
      appeal: appeal,
      parent: parent_task,
      assigned_by: assigned_by,
      assigned_to: task_type.default_assignee(parent_task),
      instructions: params[:instructions]
    )
  end
end

require_dependency "address_change_mail_task"
require_dependency "aod_motion_mail_task"
require_dependency "appeal_withdrawal_mail_task"
require_dependency "cavc_correspondence_mail_task"
require_dependency "clear_and_unmistakeable_error_mail_task"
require_dependency "congressional_interest_mail_task"
require_dependency "controlled_correspondence_mail_task"
require_dependency "death_certificate_mail_task"
require_dependency "docket_switch_mail_task"
require_dependency "evidence_or_argument_mail_task"
require_dependency "extension_request_mail_task"
require_dependency "foia_request_mail_task"
require_dependency "hearing_related_mail_task"
require_dependency "other_motion_mail_task"
require_dependency "power_of_attorney_related_mail_task"
require_dependency "privacy_act_request_mail_task"
require_dependency "privacy_complaint_mail_task"
require_dependency "reconsideration_motion_mail_task"
require_dependency "returned_undeliverable_correspondence_mail_task"
require_dependency "status_inquiry_mail_task"
require_dependency "vacate_motion_mail_task"
