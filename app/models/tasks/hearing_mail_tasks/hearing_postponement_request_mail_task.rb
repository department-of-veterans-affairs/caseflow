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

    if active_schedule_hearing_task? || open_assign_hearing_disposition_task?
      TASK_ACTIONS
    else
      [
        Constants.TASK_ACTIONS.CHANGE_TASK_TYPE.to_h,
        Constants.TASK_ACTIONS.CANCEL_TASK.to_h
      ]
    end
  end

  def update_from_params(params, user)
    payload_values = params.delete(:business_payloads)&.dig(:values)

    if params[:status] == Constants.TASK_STATUSES.completed
      # If request to postpone hearing is granted
      if payload_values[:granted]
        created_tasks = update_hearing_and_create_hearing_tasks(payload_values[:after_disposition_update])
        update_self_and_parent_mail_task(user: user, params: params, payload_values: payload_values)

        [self] + created_tasks
      # If request to postpone hearing is denied
      else
        "TO-DO: LOGIC FOR APPEALS-27763"
      end
    else
      super(params, user)
    end
  end

  # Only show HPR mail task assigned to "HearingAdmin" on the Case Timeline
  def hide_from_case_timeline
    assigned_to.type == "MailTeam"
  end

  private

  def hearing
    # TO-DO: Is this acceptable? Especially in case of request recieved after hearing held?
    #   - On that note, #available_actions might also fail?
    @hearing ||= appeal.hearings.last
  end

  def hearing_task
    @hearing_task ||= hearing.hearing_task
  end

  def active_schedule_hearing_task?
    appeal.tasks.where(type: ScheduleHearingTask.name).active.any?
  end

  def open_assign_hearing_disposition_task?
    # ChangeHearingDispositionTask is a subclass of AssignHearingDispositionTask
    disposition_task_names = [AssignHearingDispositionTask.name, ChangeHearingDispositionTask.name]
    open_task = appeal.tasks.where(type: disposition_task_names).open.first

    return false unless open_task&.hearing

    # Ensure hearing associated with AssignHearingDispositionTask is not scheduled in the past
    !open_task.hearing.scheduled_for_past?
  end

  def update_hearing_and_create_hearing_tasks(after_disposition_update)
    multi_transaction do
      update_hearing(disposition: Constants.HEARING_DISPOSITION_TYPES.postponed)
      clean_up_virtual_hearing
      reschedule_or_schedule_later(after_disposition_update)
    end
  end

  def update_hearing(hearing_hash)
    # Ensure the hearing exists
    fail HearingAssociationMissing, hearing_task&.id if hearing.nil?

    if hearing.is_a?(LegacyHearing)
      hearing.update_caseflow_and_vacols(hearing_hash)
    else
      hearing.update(hearing_hash)
    end
  end

  # TO DO: AFFECTED BY WEBEX/PEXIP?
  def clean_up_virtual_hearing
    if hearing.virtual?
      perform_later_or_now(VirtualHearings::DeleteConferencesJob)
    end
  end

  def reschedule_or_schedule_later(after_disposition_update)
    case after_disposition_update
    when "reschedule"
      "TO-DO: LOGIC FOR APPEALS-24998"
    when "schedule_later"
      schedule_later
    else
      fail ArgumentError, "unknown disposition action"
    end
  end

  def schedule_later
    new_hearing_task = hearing_task.cancel_and_recreate

    schedule_task = ScheduleHearingTask.create!(appeal: appeal, parent: new_hearing_task)

    [new_hearing_task, schedule_task].compact
  end

  def update_self_and_parent_mail_task(user:, params:, payload_values:)
    updated_instructions = format_instructions_on_completion(
      admin_context: params[:instructions],
      granted: payload_values[:granted],
      date_of_ruling: payload_values[:date_of_ruling]
    )

    multi_transaction do
      update!(
        completed_by: user,
        status: Constants.TASK_STATUSES.completed,
        instructions: updated_instructions
      )
      update_parent_status
    end
  end

  def format_instructions_on_completion(admin_context:, granted:, date_of_ruling:)
    formatted_date = date_of_ruling.to_date.strftime("%m/%d/%Y")

    text_to_append = <<~TEXT

      ***

      **Marked as complete:**

      **DECISION**
      Motion to postpone #{granted ? 'GRANTED' : 'DENIED'}

      **DATE OF RULING**
      #{formatted_date}

      **DETAILS**
      #{admin_context}
    TEXT

    [instructions[0] + text_to_append]
  end
end
