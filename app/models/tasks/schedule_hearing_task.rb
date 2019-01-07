class ScheduleHearingTask < GenericTask
  class << self
    def create_from_params(params, current_user)
      root_task = RootTask.find_or_create_by!(appeal: params[:appeal])
      params[:parent_id] = root_task.id

      task_payloads = params.delete(:business_payloads)
      child_task = super(params, current_user)
      child_task.task_business_payloads.create(task_payloads) if task_payloads

      child_task
    end
  end

  def update_from_params(params, current_user)
    verify_user_can_update!(current_user)

    task_payloads = params.delete(:business_payloads)
    scheduled_for = task_payloads[:values][:scheduled_for]
    new_date = Time.use_zone("Eastern Time (US & Canada)") do
      Time.zone.parse(scheduled_for)
    end
    task_payloads[:values][:scheduled_for] = new_date

    if !task_business_payloads.empty?
      task_business_payloads.update(task_payloads)
    else
      task_business_payloads.create(task_payloads)
    end

    super(params, current_user)
  end

  def update_parent_status
    hearing_pkseq = task_business_payloads[0].values["hearing_pkseq"]
    hearing_type = task_business_payloads[0].values["hearing_type"]
    scheduled_for = Time.zone.parse(task_business_payloads[0].values["scheduled_for"])
    scheduled_for_str = "#{scheduled_for.year}-#{scheduled_for.month}-#{scheduled_for.day} " \
                       "#{format('%##d', scheduled_for.hour)}:#{format('%##d', scheduled_for.min)}:00"

    if hearing_type == LegacyHearing::CO_HEARING
      HearingRepository.update_co_hearing(scheduled_for_str, appeal)
    else
      HearingRepository.create_child_video_hearing(hearing_pkseq, scheduled_for, appeal)
    end

    AppealRepository.update_location!(appeal, location_based_on_hearing_type(hearing_type))

    super
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
end
