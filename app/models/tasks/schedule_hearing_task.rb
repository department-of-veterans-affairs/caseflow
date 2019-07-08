# frozen_string_literal: true

##
# Task to schedule a hearing for a veteran making a claim.
# Created by the intake process for any appeal electing to have a hearing.
# Once completed, an AssignHearingDispositionTask is created.

class ScheduleHearingTask < GenericTask
  before_validation :set_assignee
  before_create :create_parent_hearing_task

  class << self
    def tasks_for_ro(regional_office)
      # Get all tasks associated with AMA appeals and the regional_office
      incomplete_tasks = ScheduleHearingTask.where(
        "status = ? OR status = ?",
        Constants.TASK_STATUSES.assigned.to_sym,
        Constants.TASK_STATUSES.in_progress.to_sym
      ).includes(:assigned_to, :assigned_by, appeal: [:available_hearing_locations], attorney_case_reviews: [:attorney])

      appeal_tasks = incomplete_tasks.joins(
        "INNER JOIN appeals ON appeals.id = appeal_id AND tasks.appeal_type = 'Appeal'"
      ).where("appeals.closest_regional_office = ?", regional_office)

      appeal_tasks + legacy_appeal_tasks(regional_office, incomplete_tasks)
    end

    private

    def legacy_appeal_tasks(regional_office, incomplete_tasks)
      joined_incomplete_tasks = incomplete_tasks.joins(
        "INNER JOIN legacy_appeals ON legacy_appeals.id = appeal_id AND tasks.appeal_type = 'LegacyAppeal'"
      )

      central_office_ids = VACOLS::Case.where(bfhr: 1, bfcurloc: "CASEFLOW").pluck(:bfkey)
      central_office_legacy_appeal_ids = LegacyAppeal.where(vacols_id: central_office_ids).pluck(:id)

      # For legacy appeals, we need to only provide a central office hearing if they explicitly
      # chose one. Likewise, we can't use DC if it's the closest regional office unless they
      # chose a central office hearing.
      if regional_office == "C"
        joined_incomplete_tasks.where("legacy_appeals.id IN (?)", central_office_legacy_appeal_ids)
      else
        tasks_by_ro = joined_incomplete_tasks.where("legacy_appeals.closest_regional_office = ?", regional_office)

        # For context: https://github.com/rails/rails/issues/778#issuecomment-432603568
        if central_office_legacy_appeal_ids.empty?
          tasks_by_ro
        else
          tasks_by_ro.where("legacy_appeals.id NOT IN (?)", central_office_legacy_appeal_ids)
        end
      end
    end
  end

  def label
    "Schedule hearing"
  end

  def create_parent_hearing_task
    if parent.type != HearingTask.name
      self.parent = HearingTask.create(appeal: appeal, parent: parent)
    end
  end

  def update_from_params(params, current_user)
    multi_transaction do
      verify_user_can_update!(current_user)

      if params[:status] == Constants.TASK_STATUSES.completed
        task_payloads = params.delete(:business_payloads)

        scheduled_time_string = task_payloads[:values][:scheduled_time_string]
        hearing_day_id = task_payloads[:values][:hearing_day_id]
        hearing_location = task_payloads[:values][:hearing_location]

        hearing = HearingRepository.slot_new_hearing(hearing_day_id,
                                                     appeal: appeal,
                                                     hearing_location_attrs: hearing_location&.to_hash,
                                                     scheduled_time_string: scheduled_time_string)
        AssignHearingDispositionTask.create_assign_hearing_disposition_task!(appeal, parent, hearing)
      elsif params[:status] == Constants.TASK_STATUSES.cancelled
        withdraw_hearing
      end

      super(params, current_user)
    end
  end

  def create_change_hearing_disposition_task(instructions = nil)
    hearing_task = most_recent_closed_hearing_task_on_appeal

    if hearing_task&.hearing&.disposition.blank?
      fail Caseflow::Error::ActionForbiddenError, message: COPY::REQUEST_HEARING_DISPOSITION_CHANGE_FORBIDDEN_ERROR
    end

    # cancel my children, myself, and my hearing task ancestor
    children.open.update_all(status: Constants.TASK_STATUSES.cancelled)
    update!(status: Constants.TASK_STATUSES.cancelled)
    ancestor_task_of_type(HearingTask)&.update!(status: Constants.TASK_STATUSES.cancelled)

    # cancel the old HearingTask and create a new one associated with the same hearing
    new_hearing_task = hearing_task.cancel_and_recreate
    HearingTaskAssociation.create!(hearing: hearing_task.hearing, hearing_task: new_hearing_task)

    # create a ChangeHearingDispositionTask on the new HearingTask
    new_hearing_task.create_change_hearing_disposition_task(instructions)
  end

  def available_actions(user)
    hearing_admin_actions = available_hearing_user_actions(user)

    if (assigned_to &.== user) || HearingsManagement.singleton.user_has_access?(user)
      return [
        Constants.TASK_ACTIONS.SCHEDULE_VETERAN.to_h,
        Constants.TASK_ACTIONS.ADD_ADMIN_ACTION.to_h,
        Constants.TASK_ACTIONS.TOGGLE_TIMED_HOLD.to_h,
        Constants.TASK_ACTIONS.WITHDRAW_HEARING.to_h
      ] | hearing_admin_actions
    end

    hearing_admin_actions
  end

  private

  def set_assignee
    self.assigned_to ||= Bva.singleton
  end

  def withdraw_hearing
    if appeal.is_a?(LegacyAppeal)
      location = if appeal.representatives.empty?
                   LegacyAppeal::LOCATION_CODES[:case_storage]
                 else
                   LegacyAppeal::LOCATION_CODES[:service_organization]
                 end

      AppealRepository.withdraw_hearing!(appeal)
      AppealRepository.update_location!(appeal, location)
    else
      EvidenceSubmissionWindowTask.create!(
        appeal: appeal,
        parent: parent,
        assigned_to: MailTeam.singleton
      )
    end
  end
end
