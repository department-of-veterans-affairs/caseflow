# frozen_string_literal: true

##
# Task to process a hearing postponement request received via the mail
#
# When this task is created:
#   - It's parent task is set as the RootTask of the associated appeal
#   - The task is assigned to the MailTeam to track where the request originated
#   - A child task of the same name is created and assigned to the HearingAdmin organization
##
class HearingPostponementRequestMailTask < HearingRequestMailTask
  prepend HearingPostponed
  include RunAsyncable
  class << self
    def label
      COPY::HEARING_POSTPONEMENT_REQUEST_MAIL_TASK_LABEL
    end

    def allow_creation?(*)
      true
    end
  end

  TASK_ACTIONS = [
    Constants.TASK_ACTIONS.CHANGE_TASK_TYPE.to_h,
    Constants.TASK_ACTIONS.COMPLETE_AND_POSTPONE.to_h,
    Constants.TASK_ACTIONS.ASSIGN_TO_TEAM.to_h,
    Constants.TASK_ACTIONS.ASSIGN_TO_PERSON.to_h,
    Constants.TASK_ACTIONS.CANCEL_TASK.to_h
  ].freeze

  # Purpose: Determines the actions a user can take depending on their permissions and the state of the appeal
  # Params: user - The current user object
  # Return: The task actions array of objects
  def available_actions(user)
    return [] unless user.in_hearing_admin_team?

    if active_schedule_hearing_task || hearing_scheduled_and_awaiting_disposition?
      TASK_ACTIONS
    else
      [
        Constants.TASK_ACTIONS.CHANGE_TASK_TYPE.to_h,
        Constants.TASK_ACTIONS.CANCEL_TASK.to_h
      ]
    end
  end

  # Purpose: Updates the current state of the appeal
  # Params: params - The update params object
  #         user - The current user object
  # Return: The current hpr task and newly created tasks
  def update_from_params(params, user)
    payload_values = params.delete(:business_payloads)&.dig(:values) || params

    # If the request is to mark HPR mail task complete
    if payload_values[:granted]&.to_s.present?
      # If request to postpone hearing is granted
      if payload_values[:granted]
        created_tasks = update_hearing_and_create_tasks(payload_values[:after_disposition_update])
      end
      update_self_and_parent_mail_task(user: user, payload_values: payload_values)

      [self] + (created_tasks || [])
    else
      super(params, user)
    end
  end

  # Purpose: Only show HPR mail task assigned to "HearingAdmin" on the Case Timeline
  # Params: None
  # Return: boolean if task is assigned to MailTeam
  def hide_from_case_timeline
    assigned_to.is_a?(MailTeam)
  end

  # Purpose: Determines if there is an open hearing
  # Params: None
  # Return: The hearing if one exists
  def open_hearing
    @open_hearing ||= open_assign_hearing_disposition_task&.hearing
  end

  # Purpose: Gives the latest hearing task
  # Params: None
  # Return: The hearing task
  def hearing_task
    @hearing_task ||= open_hearing&.hearing_task || active_schedule_hearing_task.parent
  end

  private

  # Purpose: Gives the latest active hearing task
  # Params: None
  # Return: The latest active hearing task
  def active_schedule_hearing_task
    appeal.tasks.of_type(ScheduleHearingTask.name).active.first
  end

  # ChangeHearingDispositionTask is a subclass of AssignHearingDispositionTask
  ASSIGN_HEARING_DISPOSITION_TASKS = [
    AssignHearingDispositionTask.name,
    ChangeHearingDispositionTask.name
  ].freeze

  # Purpose: Gives the latest active assign hearing disposition task
  # Params: None
  # Return: The latest active assign hearing disposition task
  def open_assign_hearing_disposition_task
    @open_assign_hearing_disposition_task ||= appeal.tasks.where(type: ASSIGN_HEARING_DISPOSITION_TASKS).open&.first
  end

  # Purpose: Associated appeal has an upcoming hearing with an open status
  # Params: None
  # Return: Returns a boolean if the appeal has an upcoming hearing
  def hearing_scheduled_and_awaiting_disposition?
    return false unless open_hearing

    # Ensure associated hearing is not scheduled for the past
    !open_hearing.scheduled_for_past?
  end

  # Purpose: Sets the previous hearing's disposition to postponed
  # Params: None
  # Return: Returns a boolean for if the hearing has been updated
  def postpone_previous_hearing
    update_hearing(disposition: Constants.HEARING_DISPOSITION_TYPES.postponed)
  end

  # Purpose: Wrapper for updating hearing and creating new hearing tasks
  # Params: Params object for additional tasks or updates after updating the hearing
  # Return: Returns the newly created tasks
  def update_hearing_and_create_tasks(after_disposition_update)
    multi_transaction do
      # If hearing exists, postpone previous hearing and handle conference links
      if open_hearing
        postpone_previous_hearing
        clean_up_virtual_hearing
      end
      # Schedule hearing or create new ScheduleHearingTask depending on after disposition action
      reschedule_or_schedule_later(after_disposition_update)
    end
  end

  # Purpose: Sets the previous hearing's disposition
  # Params: None
  # Return: Returns a boolean for if the hearing has been updated
  def update_hearing(hearing_hash)
    if open_hearing.is_a?(LegacyHearing)
      open_hearing.update_caseflow_and_vacols(hearing_hash)
    else
      open_hearing.update(hearing_hash)
    end
  end

  # Purpose: Deletes the old scheduled virtual hearings
  # Params: None
  # Return: Returns nil
  def clean_up_virtual_hearing
    if open_hearing.virtual?
      perform_later_or_now(VirtualHearings::DeleteConferencesJob)
    end
  end

  # Purpose: Either reschedule or send to schedule veteran list
  # Params: None
  # Return: Returns newly created tasks
  def reschedule_or_schedule_later(after_disposition_update)
    case after_disposition_update[:action]
    when "reschedule"
      new_hearing_attrs = after_disposition_update[:new_hearing_attrs]
      reschedule(
        hearing_day_id: new_hearing_attrs[:hearing_day_id],
        scheduled_time_string: new_hearing_attrs[:scheduled_time_string],
        hearing_location: new_hearing_attrs[:hearing_location],
        virtual_hearing_attributes: new_hearing_attrs[:virtual_hearing_attributes],
        notes: new_hearing_attrs[:notes],
        email_recipients_attributes: new_hearing_attrs[:email_recipients]
      )
    when "schedule_later"
      schedule_later
    else
      fail ArgumentError, "unknown disposition action"
    end
  end

  # rubocop:disable Metrics/ParameterLists
  # Purpose: Reschedules the hearings
  # Params: hearing_day_id - The ID of the hearing day that its going to be scheduled
  #         scheduled_time_string - The string for the scheduled time
  #         hearing_location - The hearing location string
  #         virtual_hearing_attributes - object for virtual hearing attributes
  #         notes - additional notes for the hearing string
  #         email_recipients_attributes - the object for the email recipients
  # Return: Returns new hearing and assign disposition task
  def reschedule(
    hearing_day_id:,
    scheduled_time_string:,
    hearing_location: nil,
    virtual_hearing_attributes: nil,
    notes: nil,
    email_recipients_attributes: nil
  )
    multi_transaction do
      new_hearing_task = hearing_task.cancel_and_recreate

      new_hearing = HearingRepository.slot_new_hearing(hearing_day_id: hearing_day_id,
                                                       appeal: appeal,
                                                       hearing_location_attrs: hearing_location&.to_hash,
                                                       scheduled_time_string: scheduled_time_string,
                                                       notes: notes)
      if virtual_hearing_attributes.present?
        @alerts = VirtualHearings::ConvertToVirtualHearingService
          .convert_hearing_to_virtual(new_hearing, virtual_hearing_attributes)
      elsif email_recipients_attributes.present?
        create_or_update_email_recipients(new_hearing, email_recipients_attributes)
      end

      disposition_task = AssignHearingDispositionTask
        .create_assign_hearing_disposition_task!(appeal, new_hearing_task, new_hearing)

      [new_hearing_task, disposition_task]
    end
  end
  # rubocop:enable Metrics/ParameterLists

  # Purpose: Sends the appeal back to the scheduling list
  # Params: None
  # Return: Returns the new hearing task and schedule task
  def schedule_later
    new_hearing_task = hearing_task.cancel_and_recreate
    schedule_task = ScheduleHearingTask.create!(appeal: appeal, parent: new_hearing_task)

    [new_hearing_task, schedule_task].compact
  end

  # Purpose: Completes the Mail task assigned to the MailTeam and the one for HearingAdmin
  # Params: user - The current user object
  # payload_values - The attributes needed for the update
  # Return: Boolean for if the tasks have been updated
  def update_self_and_parent_mail_task(user:, payload_values:)
    # Append instructions/context provided by HearingAdmin to original details from MailTeam
    updated_instructions = format_instructions_on_completion(
      admin_context: payload_values[:instructions],
      ruling: payload_values[:granted] ? "GRANTED" : "DENIED",
      date_of_ruling: payload_values[:date_of_ruling]
    )

    # Complete HPR mail task assigned to HearingAdmin
    update!(
      completed_by: user,
      status: Constants.TASK_STATUSES.completed,
      instructions: updated_instructions
    )
    # Complete parent HPR mail task assigned to MailTeam
    update_parent_status
  end

  # Purpose: Appends instructions on to the instructions provided in the mail task
  # Params: admin_context - String for instructions
  # ruling - string for granted or denied
  # date_of_ruling - string for the date of ruling
  # Return: instructions string
  def format_instructions_on_completion(admin_context:, ruling:, date_of_ruling:)
    formatted_date = date_of_ruling.to_date&.strftime("%m/%d/%Y")

    markdown_to_append = <<~EOS

      ***

      ###### Marked as complete:

      **DECISION**
      Motion to postpone #{ruling}

      **DATE OF RULING**
      #{formatted_date}

      **DETAILS**
      #{admin_context}
    EOS

    [instructions[0] + markdown_to_append]
  end
end
