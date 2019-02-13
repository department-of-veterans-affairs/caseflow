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

    def legacy_tasks_for_ro(regional_office, incomplete_tasks)
      # Joining to legacy appeals is more difficult because we don't store the veteran file number
      # we only have the bfcorlid, which needs to be modified according to the
      # LegacyAppeal.veteran_file_number_from_bfcorlid function. It is written here in SQL.
      legacy_appeal_tasks = incomplete_tasks
        .joins("INNER JOIN legacy_appeals ON legacy_appeals.id = appeal_id")
        .joins("INNER JOIN veterans ON
                  CASE
                    WHEN substring(legacy_appeals.vbms_id from length(legacy_appeals.vbms_id) for 1) = 'C'
                      THEN lpad(regexp_replace(legacy_appeals.vbms_id, '[^0-9]', ''), 8, '0')
                    ELSE regexp_replace(legacy_appeals.vbms_id, '[^0-9]', '')
                  END = veterans.file_number")

      central_office_ids = VACOLS::Case.where(bfhr: 1, bfcurloc: "CASEFLOW").pluck(:bfkey)
      central_office_legacy_appeal_ids = LegacyAppeal.where(vacols_id: central_office_ids).pluck(:id)

      # For legacy appeals, we need to only provide a central office hearing if they explicitly
      # chose one. Likewise, we can't use DC if it's the closest regional office unless they
      # chose a central office hearing.
      if regional_office == "C"
        legacy_appeal_tasks.where("legacy_appeals.id IN (?)", central_office_legacy_appeal_ids)
      else
        tasks_by_ro = legacy_appeal_tasks.where("veterans.closest_regional_office = ?", regional_office)

        # For context: https://github.com/rails/rails/issues/778#issuecomment-432603568
        if central_office_legacy_appeal_ids.empty?
          tasks_by_ro
        else
          tasks_by_ro.where("legacy_appeals.id NOT IN (?)", central_office_legacy_appeal_ids)
        end
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
        .joins("INNER JOIN veterans ON appeals.veteran_file_number = veterans.file_number")
        .where("veterans.closest_regional_office = ?", regional_office)

      legacy_tasks_for_ro(regional_office, incomplete_tasks) + appeal_tasks
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
