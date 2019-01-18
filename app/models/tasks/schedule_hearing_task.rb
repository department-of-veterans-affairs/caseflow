class ScheduleHearingTask < GenericTask
  class << self
    def create_if_eligible(appeal)
      if appeal.is_a?(LegacyAppeal) && appeal.case_record.bfcurloc == "57"
        ScheduleHearingTask.find_or_create_by!(appeal: appeal) do |task|
          task.update(
            assigned_to: HearingsManagement.singleton,
            parent: RootTask.find_or_create_by!(appeal: appeal)
          )
        end
      end
    end

    def tasks_for_ro(regional_office)
      # Get all legacy tasks for this RO
      legacy_appeal_tasks = AppealRepository.appeals_ready_for_hearing_schedule(regional_office).map do |appeal|
        ScheduleHearingTask.new(
          appeal: appeal,
          status: Constants.TASK_STATUSES.in_progress.to_sym,
          assigned_to: HearingsManagement.singleton
        )
      end

      # Get all tasks associated with AMA appeals and the regional_office
      appeal_tasks = ScheduleHearingTask.where(
        appeal_type: Appeal.name,
        status: Constants.TASK_STATUSES.assigned.to_sym
      ).joins("INNER JOIN appeals ON appeals.id = appeal_id")
        .joins("INNER JOIN veterans ON appeals.veteran_file_number = veterans.file_number")
        .where("veterans.closest_regional_office = ?", regional_office)

      legacy_appeal_tasks + appeal_tasks
    end
  end

  def update_from_params(params, current_user)
    verify_user_can_update!(current_user)

    task_payloads = params.delete(:business_payloads)

    hearing_date = Time.use_zone("Eastern Time (US & Canada)") do
      Time.zone.parse(task_payloads[:values][:hearing_date])
    end
    hearing_day_id = task_payloads[:values][:hearing_pkseq]
    hearing_type = task_payloads[:values][:hearing_type]

    update_hearing(hearing_day_id, hearing_date, hearing_type) if params[:status] == Constants.TASK_STATUSES.completed

    super(params, current_user)
  end

  def location_based_on_hearing_type(hearing_type)
    if hearing_type == LegacyHearing::CO_HEARING
      LegacyAppeal::LOCATION_CODES[:awaiting_co_hearing]
    else
      LegacyAppeal::LOCATION_CODES[:awaiting_video_hearing]
    end
  end

  def available_actions(user)
    if (assigned_to && assigned_to == user) || task_is_assigned_to_users_organization?(user)
      return [
        Constants.TASK_ACTIONS.SCHEDULE_VETERAN.to_h
      ]
    end

    []
  end

  private

  def update_hearing(hearing_day_id, hearing_date, hearing_type)
    hearing_date_str = "#{hearing_date.year}-#{hearing_date.month}-#{hearing_date.day} " \
                       "#{format('%##d', hearing_date.hour)}:#{format('%##d', hearing_date.min)}:00"

    if hearing_type == LegacyHearing::CO_HEARING
      HearingRepository.update_co_hearing(hearing_date_str, appeal)
    else
      HearingRepository.create_child_video_hearing(hearing_day_id, hearing_date, appeal)
    end

    if appeal.is_a?(LegacyAppeal)
      AppealRepository.update_location!(appeal, location_based_on_hearing_type(hearing_type))
    end
  end
end
