class ScheduleHearingTask < GenericTask
  class << self
    def create_from_params(params, current_user)
      root_task = RootTask.find_by(appeal_id: params[:appeal].id)
      if !root_task
        root_task = RootTask.create!(appeal_id: params[:appeal].id,
                                     appeal_type: "LegacyAppeal",
                                     assigned_to_id: current_user.id)
      end
      params[:parent_id] = root_task.id

      task_payloads = params.delete(:business_payloads)
      child_task = super(params, current_user)
      child_task.task_business_payloads.create(task_payloads) if task_payloads

      child_task
    end

    def create_child_task(parent, current_user, params)
      # Create an assignee from the input arguments so we throw an error if the assignee does not exist.
      assignee = Object.const_get(params[:assigned_to_type]).find(params[:assigned_to_id])

      parent.update!(status: :on_hold)

      create!(
        appeal: parent.appeal,
        appeal_type: "LegacyAppeal",
        assigned_by_id: child_assigned_by_id(parent, current_user),
        parent_id: parent.id,
        assigned_to: assignee,
        instructions: params[:instructions]
      )
    end
  end

  def mark_as_complete!
    hearing_pkseq = task_business_payloads[0].values[2]
    Rails.logger.info("OARVT hearing_pkseq #{hearing_pkseq} .")
    hearing_type = task_business_payloads[0].values[3]
    hearing = VACOLS::CaseHearing.find(hearing_pkseq)

    if hearing_type == "Central"
      HearingRepository.update_vacols_hearing!(hearing, folder_nr: appeal.vacols_id)
    else
      hearing_hash = to_hash(hearing)
      hearing_hash[:folder_nr] = appeal.vacols_id
      # hearing date should be from payload.
      hearing_hash[:hearing_date] = task_business_payloads[0].values[4].to_s
      Rails.logger.info("OARVT hearing_hash #{hearing_hash} .")
      HearingRepository.create_vacols_child_hearing(hearing_hash)
    end

    AppealRepository.update_location!(appeal, location_based_on_hearing_type(hearing_type))

    super
  end

  def location_based_on_hearing_type(hearing_type)
    if hearing_type == "Central"
      LegacyAppeal::LOCATION_CODES[:awaiting_co_hearing]
    else
      LegacyAppeal::LOCATION_CODES[:awaiting_video_hearing]
    end
  end

  def available_actions(_user)
    [
      Constants.TASK_ACTIONS.SCHEDULE_VETERAN.to_h
    ]
  end

  private

  def to_hash(hearing)
    hearing.as_json.each_with_object({}) do |(k, v), result|
      result[k.to_sym] = v
    end
  end
end
