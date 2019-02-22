class TranscriptionTask < GenericTask
  def available_actions(_user)
    [Constants.TASK_ACTIONS.RESCHEDULE_HEARING.to_h, Constants.TASK_ACTIONS.COMPLETE_TRANSCRIPTION.to_h]
  end

  def assign_to_hearing_schedule_team_data(_user)
    {
      redirect_after: "/queue/appeals/#{appeal.external_id}",
      modal_title: COPY::RETURN_CASE_TO_HEARINGS_MANAGEMENT_TITLE,
      modal_body: COPY::RETURN_CASE_TO_HEARINGS_MANAGEMENT_BODY,
      message_title: format(COPY::RETURN_CASE_TO_HEARINGS_MANAGEMENT_MESSAGE_TITLE, appeal.veteran_full_name),
      message_detail: format(COPY::RETURN_CASE_TO_HEARINGS_MANAGEMENT_MESSAGE_BODY, appeal.veteran_full_name)
    }
  end

  def update_from_params(params, current_user)
    multi_transaction do
      verify_user_can_update!(current_user)

      if params[:status] == Constants.TASK_STATUSES.cancelled
        withdraw_hearing
        params[:status] = Constants.TASK_STATUSES.completed
      end

      super(params, current_user)
    end
  end

  def recreate_hearing
    # We need to close the parent task and all the sibling tasks as well as open up a new
    # ScheduleHearingTask assigned to the hearing branch
    parent.update!(status: Constants.TASK_STATUSES.cancelled)
    parent.chidren.update(status: Constants.TASK_STATUSES.cancelled)


  end

  def hearing_task
    return @hearing_task if @hearing_task
    
    @hearing_task = parent
    while @hearing_task.class != HearingTask
      @hearing_task = @hearing_task.parent
    end
    @hearing_task
  end
end
