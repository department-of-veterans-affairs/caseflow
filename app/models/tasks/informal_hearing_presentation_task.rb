# frozen_string_literal: true

##
# Task assigned to VSOs to submit an Informal Hearing Presentation for Veterans who have elected not to have a hearing.
# IHPs are a chance for VSOs to make final arguments before a case is sent to the Board.
# BVA typically (but not always) waits for an IHP to be submitted before making a decision.
#
# If an appeal is in the Direct Review docket, this task is automatically created as a child of DistributionTask if the
# representing VSO `should_write_ihp?(appeal)` -- see `IhpTasksFactory.create_ihp_tasks!`.
#
# For an Evidence Submission docket, this task is created as the child of DistributionTask
# after the 90 evidence submission window is complete.

class InformalHearingPresentationTask < Task
  # https://github.com/department-of-veterans-affairs/caseflow/issues/10824
  # Figure out how long IHP tasks will take to expire,
  # then make them timeable
  # include TimeableTask

  USER_ACTIONS = [
    Constants.TASK_ACTIONS.REASSIGN_TO_PERSON.to_h,
    Constants.TASK_ACTIONS.TOGGLE_TIMED_HOLD.to_h,
    Constants.TASK_ACTIONS.MARK_COMPLETE.to_h,
    Constants.TASK_ACTIONS.CANCEL_TASK.to_h
  ].freeze

  ADMIN_ACTIONS = [
    Constants.TASK_ACTIONS.REASSIGN_TO_PERSON.to_h
  ].freeze

  ORG_ACTIONS = [
    Constants.TASK_ACTIONS.ASSIGN_TO_PERSON.to_h,
    Constants.TASK_ACTIONS.MARK_COMPLETE.to_h,
    Constants.TASK_ACTIONS.CANCEL_TASK.to_h
  ].freeze

  def available_actions(user)
    return USER_ACTIONS if assigned_to == user

    return ADMIN_ACTIONS if task_is_assigned_to_user_within_organization?(user) &&
                            parent.assigned_to.user_is_admin?(user)

    return ORG_ACTIONS if task_is_assigned_to_users_organization?(user)

    []
  end

  def self.label
    COPY::IHP_TASK_LABEL
  end

  def update_from_params(params, user)
    transaction do
      ihp_path = params.delete(:ihp_path)

      if FeatureToggle.enabled?(:ihp_notification) && params[:status] == Constants.TASK_STATUSES.completed
        IhpDraft.create_or_update_from_task!(self, ihp_path)
      end

      super(params, user)
    end
  end

  def update_parent_task(appeal)
    newIHP = appeal.tasks.open.where(type: :InformalHearingPresentationTask).first
    dist_task = appeal.tasks.where(type: :DistributionTask).first
    if newIHP && dist_task
      newIHP.update(parent: dist_task)
      dist_task.on_hold!
    end
  end

  def self.update_to_new_poa(appeal)
    begin
      TrackVeteranTask.sync_tracking_tasks(appeal)
      update_parent_task(appeal)
    rescue StandardError => error
      Raven.capture_exception(error)
      nil
    end
  end
end
