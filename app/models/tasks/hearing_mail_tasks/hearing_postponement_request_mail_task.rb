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

  # Only show HPR mail task assigned to "HearingAdmin" on the Case Timeline
  def hide_from_case_timeline
    assigned_to.is_a?(MailTeam)
  end

  def open_hearing
    @open_hearing ||= open_assign_hearing_disposition_task&.hearing
  end

  def hearing_task
    @hearing_task ||= open_hearing&.hearing_task || active_schedule_hearing_task&.parent
  end

  private

  def active_schedule_hearing_task
    appeal.tasks.where(type: ScheduleHearingTask.name).active.first
  end

  # ChangeHearingDispositionTask is a subclass of AssignHearingDispositionTask
  ASSIGN_HEARING_DISPOSITION_TASKS = [
    AssignHearingDispositionTask.name,
    ChangeHearingDispositionTask.name
  ].freeze

  def open_assign_hearing_disposition_task
    @open_assign_hearing_disposition_task ||= appeal.tasks.where(type: ASSIGN_HEARING_DISPOSITION_TASKS).open.first
  end

  # Associated appeal has an upcoming hearing with an open status
  def hearing_scheduled_and_awaiting_disposition?
    return false if open_hearing.nil?

    # Ensure associated hearing is not scheduled for the past
    !open_hearing.scheduled_for_past?
  end

  def update_hearing_and_create_tasks(after_disposition_update)
    multi_transaction do
      # If hearing exists, postpone previous hearing and handle conference links
      unless open_hearing.nil?
        update_hearing(disposition: Constants.HEARING_DISPOSITION_TYPES.postponed)
        clean_up_virtual_hearing
      end
      # Schedule hearing or create new ScheduleHearingTask depending on after disposition action
      reschedule_or_schedule_later(after_disposition_update)
    end
  end

  def update_hearing(hearing_hash)
    if open_hearing.is_a?(LegacyHearing)
      open_hearing.update_caseflow_and_vacols(hearing_hash)
    else
      open_hearing.update(hearing_hash)
    end
  end

  def clean_up_virtual_hearing
    if open_hearing.virtual?
      perform_later_or_now(VirtualHearings::DeleteConferencesJob)
    end
  end

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

  def schedule_later
    new_hearing_task = hearing_task.cancel_and_recreate
    schedule_task = ScheduleHearingTask.create!(appeal: appeal, parent: new_hearing_task)

    [new_hearing_task, schedule_task].compact
  end

  def update_self_and_parent_mail_task(user:, payload_values:)
    # Append instructions/context provided by HearingAdmin to original details from MailTeam
    updated_instructions = format_instructions_on_completion(
      admin_context: payload_values[:instructions],
      granted: payload_values[:granted],
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

  def format_instructions_on_completion(admin_context:, granted:, date_of_ruling:)
    formatted_date = date_of_ruling.to_date.strftime("%m/%d/%Y")

    markdown_to_append = <<~EOS

      ***

      ###### Marked as complete:

      **DECISION**
      Motion to postpone #{granted ? 'GRANTED' : 'DENIED'}

      **DATE OF RULING**
      #{formatted_date}

      **DETAILS**
      #{admin_context}
    EOS

    [instructions[0] + markdown_to_append]
  end
end
