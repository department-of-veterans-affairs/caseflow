# frozen_string_literal: true

##
# Task to schedule a hearing for a veteran making a claim.
# Created by the intake process for any appeal electing to have a hearing.
# Once completed, a DispositionTask is created.

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

  # We only want to take this off hold, not actually complete it, like the inherited method does
  def update_status_if_children_tasks_are_complete
    update!(status: :assigned) if on_hold?
  end

  def update_from_params(params, current_user)
    multi_transaction do
      verify_user_can_update!(current_user)

      if params[:status] == Constants.TASK_STATUSES.completed
        task_payloads = params.delete(:business_payloads)

        hearing_time = task_payloads[:values][:hearing_time]
        hearing_day_id = task_payloads[:values][:hearing_day_id]
        hearing_location = task_payloads[:values][:hearing_location]

        hearing = HearingRepository.slot_new_hearing(hearing_day_id,
                                                     appeal: appeal,
                                                     hearing_location_attrs: hearing_location&.to_hash,
                                                     scheduled_time: hearing_time&.stringify_keys)
        DispositionTask.create_disposition_task!(appeal, parent, hearing)
      elsif params[:status] == Constants.TASK_STATUSES.cancelled
        withdraw_hearing
      end

      super(params, current_user)
    end
  end

  def available_actions(user)
    if (assigned_to && assigned_to == user) || HearingsManagement.singleton.user_has_access?(user)
      return [
        Constants.TASK_ACTIONS.SCHEDULE_VETERAN.to_h,
        Constants.TASK_ACTIONS.ADD_ADMIN_ACTION.to_h,
        Constants.TASK_ACTIONS.WITHDRAW_HEARING.to_h
      ]
    end

    []
  end

  def add_admin_action_data(_user)
    {
      redirect_after: "/queue/appeals/#{appeal.external_id}",
      message_detail: COPY::ADD_HEARING_ADMIN_TASK_CONFIRMATION_DETAIL,
      selected: nil,
      options: HearingAdminActionTask.subclasses.sort_by(&:label).map do |subclass|
        { value: subclass.name, label: subclass.label }
      end
    }
  end

  def withdraw_hearing_data(_user)
    {
      redirect_after: "/queue/appeals/#{appeal.external_id}",
      modal_title: COPY::WITHDRAW_HEARING_MODAL_TITLE,
      modal_body: COPY::WITHDRAW_HEARING_MODAL_BODY,
      message_title: format(COPY::WITHDRAW_HEARING_SUCCESS_MESSAGE_TITLE, appeal.veteran_full_name),
      message_detail: format(COPY::WITHDRAW_HEARING_SUCCESS_MESSAGE_BODY, appeal.veteran_full_name),
      back_to_hearing_schedule: true
    }
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
