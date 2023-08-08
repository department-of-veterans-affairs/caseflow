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

    # TO DO: BUSINESS TO DECIDE WHETHER CANCELLED OR COMPLETED
    if params[:status] == Constants.TASK_STATUSES.cancelled
      if payload_values[:granted]
        created_tasks = update_hearing_and_self(params: params, payload_values: payload_values)

        [self] + created_tasks
      else
        # TO-DO
        "LOGIC FOR DENIED REQUEST"
      end
    else
      super(params, user)
    end
  end

  private

  def hearing
    # TO-DO: In case where a HPR mail request is received after hearing has been held,
    # this wouldn't be most accurate means of grabbing the associated hearing
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

  def update_hearing_and_self(params:, payload_values:)
    mark_hearing_with_disposition(
      payload_values: payload_values,
      instructions: params["instructions"]
    )
  end

  def mark_hearing_with_disposition(payload_values:, instructions:)
    multi_transaction do
      update_hearing(disposition: Constants.HEARING_DISPOSITION_TYPES.postponed)
      clean_up_virtual_hearing
      reschedule_or_schedule_later(
        instructions: instructions,
        after_disposition_update: payload_values[:after_disposition_update]
      )
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

  def clean_up_virtual_hearing
    if hearing.virtual?
      perform_later_or_now(VirtualHearings::DeleteConferencesJob)
    end
  end

  def reschedule_or_schedule_later(instructions:, after_disposition_update:)
    case after_disposition_update
    when "reschedule"
      # TO-DO
      "LOGIC FOR APPEALS-24998"
    when "schedule_later"
      schedule_later(instructions: instructions)
    else
      fail ArgumentError, "unknown disposition action"
    end
  end

  def schedule_later(instructions:)
    new_hearing_task = hearing_task.cancel_and_recreate

    schedule_task = ScheduleHearingTask.create!(
      appeal: appeal,
      instructions: instructions,
      parent: new_hearing_task
    )

    [new_hearing_task, schedule_task].compact
  end
end
