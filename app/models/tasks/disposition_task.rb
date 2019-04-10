# frozen_string_literal: true

##
# Task assigned to the BvaOrganization after a hearing is scheduled, created after the ScheduleHearingTask is completed.
# When the associated hearing's disposition is set, the appropriate tasks are set as children
#   (e.g., TranscriptionTask, EvidenceWindowTask, etc.).
# The task is marked complete when these children tasks are completed.
class DispositionTask < GenericTask
  before_create :check_parent_type
  delegate :hearing, to: :hearing_task, allow_nil: true

  class HearingDispositionNotCanceled < StandardError; end
  class HearingDispositionNotNoShow < StandardError; end
  class HearingDispositionNotHeld < StandardError; end

  class << self
    def create_disposition_task!(appeal, parent, hearing)
      disposition_task = DispositionTask.create!(
        appeal: appeal,
        parent: parent,
        assigned_to: Bva.singleton
      )

      HearingTaskAssociation.create!(hearing: hearing, hearing_task: parent)

      disposition_task
    end
  end

  def hearing_task
    @hearing_task ||= parent
  end

  def available_actions(user)
    if JudgeTeam.for_judge(user) || HearingsManagement.singleton.user_has_access?(user)
      [Constants.TASK_ACTIONS.POSTPONE_HEARING.to_h]
    else
      []
    end
  end

  def add_schedule_hearing_task_admin_actions_data(_user)
    {
      redirect_after: "/queue/appeals/#{appeal.external_id}",
      message_detail: COPY::ADD_HEARING_ADMIN_TASK_CONFIRMATION_DETAIL,
      selected: nil,
      options: HearingAdminActionTask.subclasses.sort_by(&:label).map do |subclass|
        { value: subclass.name, label: subclass.label }
      end
    }
  end

  def update_from_params(params, user)
    payload_values = params.delete(:business_payloads)&.dig(:values)

    if params[:status] == Constants.TASK_STATUSES.cancelled
      case payload_values[:disposition]
      when "cancelled"
        mark_hearing_cancelled
      when "held"
        mark_hearing_held
      when "no_show"
        mark_hearing_no_show
      when "postponed"
        mark_hearing_postponed(
          instructions: params["instructions"],
          after_disposition_update: payload_values[:after_disposition_update]
        )
      end
    end

    super(params, user)
  end

  def cancel!
    if hearing&.disposition != Constants.HEARING_DISPOSITION_TYPES.cancelled
      fail HearingDispositionNotCanceled
    end

    update!(status: Constants.TASK_STATUSES.cancelled)
  end

  def no_show!
    if hearing&.disposition != Constants.HEARING_DISPOSITION_TYPES.no_show
      fail HearingDispositionNotNoShow
    end

    no_show_hearing_task = NoShowHearingTask.create!(
      parent: self,
      appeal: appeal,
      assigned_to: HearingAdmin.singleton
    )

    no_show_hearing_task.update!(
      status: Constants.TASK_STATUSES.on_hold,
      on_hold_duration: 25.days
    )
  end

  def hold!
    if hearing&.disposition != Constants.HEARING_DISPOSITION_TYPES.held
      fail HearingDispositionNotHeld
    end

    if appeal.is_a?(LegacyAppeal)
      complete_task
    else
      create_transcription_and_maybe_evidence_submission_window_tasks
    end
  end

  private

  def check_parent_type
    if parent.type != HearingTask.name
      fail(
        Caseflow::Error::InvalidParentTask,
        task_type: self.class.name,
        assignee_type: assigned_to.class.name
      )
    end
  end

  def reschedule(hearing_day_id:, hearing_time:, hearing_location: nil)
    new_hearing_task = hearing_task.cancel_and_recreate

    new_hearing = HearingRepository.slot_new_hearing(hearing_day_id,
                                                     appeal: appeal,
                                                     hearing_location_attrs: hearing_location&.to_hash,
                                                     scheduled_time: hearing_time.stringify_keys)
    self.class.create_disposition_task!(appeal, new_hearing_task, new_hearing)
  end

  def mark_hearing_cancelled() end

  def mark_hearing_held() end

  def mark_hearing_no_show() end

  def mark_hearing_postponed(instructions: nil, after_disposition_update: nil)
    multi_transaction do
      if hearing.is_a?(LegacyHearing)
        hearing.update_caseflow_and_vacols(disposition: "postponed")
      else
        hearing.update(disposition: "postponed")
      end

      reschedule_or_schedule_later(instructions: instructions, after_disposition_update: after_disposition_update)
    end
  end

  def reschedule_or_schedule_later(instructions: nil, after_disposition_update:)
    case after_disposition_update[:action]
    when "reschedule"
      new_hearing_attrs = after_disposition_update[:new_hearing_attrs]
      reschedule(
        hearing_day_id: new_hearing_attrs[:hearing_day_id], hearing_time: new_hearing_attrs[:hearing_time],
        hearing_location: new_hearing_attrs[:hearing_location]
      )
    when "schedule_later"
      schedule_later(
        instructions: instructions,
        with_admin_action_klass: after_disposition_update[:with_admin_action_klass],
        admin_action_instructions: after_disposition_update[:admin_action_instructions]
      )
    end
  end

  def schedule_later(instructions: nil, with_admin_action_klass: nil, admin_action_instructions: nil)
    new_hearing_task = hearing_task.cancel_and_recreate

    schedule_task = ScheduleHearingTask.create!(
      appeal: appeal,
      assigned_to: HearingsManagement.singleton,
      instructions: instructions.present? ? [instructions] : nil,
      parent: new_hearing_task
    )
    if with_admin_action_klass.present?
      with_admin_action_klass.constantize.create!(
        appeal: appeal,
        assigned_to: HearingsManagement.singleton,
        instructions: admin_action_instructions.present? ? [admin_action_instructions] : nil,
        parent: schedule_task
      )
    end
  end

  def complete_task
    update!(status: Constants.TASK_STATUSES.completed)
  end

  def create_transcription_and_maybe_evidence_submission_window_tasks
    TranscriptionTask.create!(appeal: appeal, parent: self, assigned_to: TranscriptionTeam.singleton)
    unless hearing&.evidence_window_waived
      EvidenceSubmissionWindowTask.create!(appeal: appeal, parent: self, assigned_to: MailTeam.singleton)
    end
  end
end
