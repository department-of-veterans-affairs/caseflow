class ScheduleHearingTask < GenericTask
  after_update :update_location_in_vacols

  class << self
    def find_or_create_if_eligible(appeal)
      if appeal.is_a?(LegacyAppeal) && appeal.case_record&.bfcurloc == "57" &&
         appeal.hearings.all?(&:disposition)
        ScheduleHearingTask.where.not(status: "completed").find_or_create_by!(appeal: appeal) do |task|
          task.update(
            assigned_to: HearingsManagement.singleton,
            parent: RootTask.find_or_create_by!(appeal: appeal)
          )
        end
      elsif appeal.is_a?(Appeal)
        ScheduleHearingTask.where.not(status: "completed").find_by(appeal: appeal)
      end
    end

    def tasks_for_ro(regional_office)
      # Get all tasks associated with AMA appeals and the regional_office
      incomplete_tasks = ScheduleHearingTask.where(
        "status = ? OR status = ?",
        Constants.TASK_STATUSES.assigned.to_sym,
        Constants.TASK_STATUSES.in_progress.to_sym
      ).includes(:assigned_to, :assigned_by, :appeal, attorney_case_reviews: [:attorney])

      appeal_tasks = incomplete_tasks.joins("INNER JOIN appeals ON appeals.id = appeal_id")
        .where("appeals.closest_regional_office = ?", regional_office)

      legacy_appeal_tasks = incomplete_tasks
        .joins("INNER JOIN legacy_appeals ON legacy_appeals.id = appeal_id")
        .where("legacy_appeals.closest_regional_office = ?", regional_office)

      appeal_tasks + legacy_appeal_tasks
    end
  end

  def label
    "Schedule hearing"
  end

  def update_location_in_vacols
    if saved_change_to_status? && appeal.is_a?(LegacyAppeal) && on_hold?
      AppealRepository.update_location!(appeal, LegacyAppeal::LOCATION_CODES[:caseflow])
    end
  end

  # We only want to take this off hold, not actually complete it, like the inherited method does
  def update_status_if_children_tasks_are_complete
    if appeal.is_a?(LegacyAppeal)
      AppealRepository.update_location!(appeal, LegacyAppeal::LOCATION_CODES[:schedule_hearing])
    end

    return update!(status: :assigned) if on_hold?
  end

  def update_from_params(params, current_user)
    multi_transaction do
      verify_user_can_update!(current_user)

      if params[:status] == Constants.TASK_STATUSES.completed
        task_payloads = params.delete(:business_payloads)

        hearing_time = task_payloads[:values][:hearing_time]
        hearing_day_id = task_payloads[:values][:hearing_pkseq]
        hearing_type = task_payloads[:values][:hearing_type]
        hearing_location = task_payloads[:values][:hearing_location]

        slot_new_hearing(hearing_day_id, hearing_type, hearing_time, hearing_location)
        HoldHearingTask.create_hold_hearing_task!(appeal, parent)
      elsif params[:status] == "canceled"
        withdraw_hearing
        params[:status] = Constants.TASK_STATUSES.completed
      end

      super(params, current_user)
    end
  end

  def available_actions(user)
    if (assigned_to && assigned_to == user) || task_is_assigned_to_users_organization?(user)
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

  def withdraw_hearing
    if appeal.is_a?(LegacyAppeal)
      location = if appeal.vsos.empty?
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

  def slot_new_hearing(hearing_day_id, hearing_type, hearing_time, hearing_location)
    HearingRepository.slot_new_hearing(hearing_day_id,
                                       hearing_type: (hearing_type == LegacyHearing::CO_HEARING) ? "C" : "V",
                                       appeal: appeal,
                                       hearing_location_attrs: hearing_location&.to_hash,
                                       scheduled_time: hearing_time&.stringify_keys)
    if appeal.is_a?(LegacyAppeal)
      AppealRepository.update_location!(appeal, LegacyAppeal::LOCATION_CODES[:caseflow])
    end
  end
end
