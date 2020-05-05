# frozen_string_literal: true

##
# Task assigned to the BvaOrganization after a hearing is scheduled, created after the ScheduleHearingTask
# is completed. When the associated hearing's disposition is set, the appropriate tasks are set as children
#   (e.g., TranscriptionTask, EvidenceWindowTask, etc.).
# The task is marked complete when these children tasks are completed.
class AssignHearingDispositionTask < Task
  validates :parent, presence: true
  before_create :check_parent_type
  delegate :hearing, to: :hearing_task, allow_nil: true

  class HearingDispositionNotCanceled < StandardError; end
  class HearingDispositionNotPostponed < StandardError; end
  class HearingDispositionNotNoShow < StandardError; end
  class HearingDispositionNotHeld < StandardError; end

  class << self
    def create_assign_hearing_disposition_task!(appeal, parent, hearing)
      assign_hearing_disposition_task = create!(
        appeal: appeal,
        parent: parent,
        assigned_to: Bva.singleton
      )

      HearingTaskAssociation.create!(hearing: hearing, hearing_task: parent)

      assign_hearing_disposition_task
    end
  end

  def self.label
    "Select hearing disposition"
  end

  def default_instructions
    [COPY::ASSIGN_HEARING_DISPOSITION_TASK_DEFAULT_INSTRUCTIONS]
  end

  def hearing_task
    @hearing_task ||= parent
  end

  def available_actions(user)
    hearing_admin_actions = available_hearing_user_actions(user)

    if HearingsManagement.singleton.user_has_access?(user)
      [Constants.TASK_ACTIONS.POSTPONE_HEARING.to_h] | hearing_admin_actions
    else
      hearing_admin_actions
    end
  end

  def update_from_params(params, user)
    payload_values = params.delete(:business_payloads)&.dig(:values)

    if params[:status] == Constants.TASK_STATUSES.cancelled && payload_values[:disposition].present?
      update_hearing_and_self(params: params, payload_values: payload_values)

      [self]
    else
      super(params, user)
    end
  end

  def cancel!
    if hearing&.disposition != Constants.HEARING_DISPOSITION_TYPES.cancelled
      fail HearingDispositionNotCanceled
    end

    if appeal.is_a? Appeal
      EvidenceSubmissionWindowTask.find_or_create_by!(
        appeal: appeal,
        parent: hearing_task.parent,
        assigned_to: MailTeam.singleton
      )
    end

    update!(status: Constants.TASK_STATUSES.cancelled, closed_at: Time.zone.now)
  end

  def postpone!
    if hearing&.disposition != Constants.HEARING_DISPOSITION_TYPES.postponed
      fail HearingDispositionNotPostponed
    end

    schedule_later
  end

  def no_show!
    if hearing&.disposition != Constants.HEARING_DISPOSITION_TYPES.no_show
      fail HearingDispositionNotNoShow
    end

    NoShowHearingTask.create_with_hold(self)
  end

  def hold!
    if hearing&.disposition != Constants.HEARING_DISPOSITION_TYPES.held
      fail HearingDispositionNotHeld
    end

    if appeal.is_a?(LegacyAppeal)
      update!(status: Constants.TASK_STATUSES.completed)
    else
      create_transcription_and_maybe_evidence_submission_window_tasks
    end
  end

  private

  def update_children_status_after_closed
    update_args = { status: status }
    update_args[:closed_at] = Time.zone.now if self.class.closed_statuses.include?(status)
    children.open.update_all(update_args)
  end

  def cascade_closure_from_child_task?(_child_task)
    true
  end

  def update_hearing_and_self(params:, payload_values:)
    case payload_values[:disposition]
    when Constants.HEARING_DISPOSITION_TYPES.cancelled
      mark_hearing_cancelled
    when Constants.HEARING_DISPOSITION_TYPES.held
      mark_hearing_held
    when Constants.HEARING_DISPOSITION_TYPES.no_show
      mark_hearing_no_show
    when Constants.HEARING_DISPOSITION_TYPES.postponed
      mark_hearing_postponed(
        instructions: params["instructions"],
        after_disposition_update: payload_values[:after_disposition_update]
      )
    end

    update_with_instructions(instructions: params[:instructions]) if params[:instructions].present?
  end

  def update_hearing_disposition(disposition:)
    # Ensure the hearing exists
    if hearing.nil?
      fail ActiveRecord::RecordInvalid
    end

    # Ensure the hearing task association exists
    if hearing_task.hearing_task_association.nil?
      HearingTaskAssociation.create!(hearing: hearing, hearing_task: hearing_task)
    end

    if hearing.is_a?(LegacyHearing)
      hearing.update_caseflow_and_vacols(disposition: disposition)
    else
      hearing.update(disposition: disposition)
    end
  end

  def check_parent_type
    if parent.type != HearingTask.name
      fail(
        Caseflow::Error::InvalidParentTask,
        task_type: self.class.name,
        assignee_type: assigned_to.class.name
      )
    end
  end

  def reschedule(hearing_day_id:, scheduled_time_string:, hearing_location: nil)
    new_hearing_task = hearing_task.cancel_and_recreate

    new_hearing = HearingRepository.slot_new_hearing(hearing_day_id,
                                                     appeal: appeal,
                                                     hearing_location_attrs: hearing_location&.to_hash,
                                                     scheduled_time_string: scheduled_time_string)
    self.class.create_assign_hearing_disposition_task!(appeal, new_hearing_task, new_hearing)
  end

  def mark_hearing_cancelled
    multi_transaction do
      update_hearing_disposition(disposition: Constants.HEARING_DISPOSITION_TYPES.cancelled)
      cancel!
    end
  end

  def mark_hearing_held
    multi_transaction do
      update_hearing_disposition(disposition: Constants.HEARING_DISPOSITION_TYPES.held)
      hold!
    end
  end

  def mark_hearing_no_show
    multi_transaction do
      update_hearing_disposition(disposition: Constants.HEARING_DISPOSITION_TYPES.no_show)
      no_show!
    end
  end

  def mark_hearing_postponed(instructions: nil, after_disposition_update: nil)
    multi_transaction do
      update_hearing_disposition(disposition: Constants.HEARING_DISPOSITION_TYPES.postponed)
      reschedule_or_schedule_later(instructions: instructions, after_disposition_update: after_disposition_update)
    end
  end

  def reschedule_or_schedule_later(instructions: nil, after_disposition_update:)
    case after_disposition_update[:action]
    when "reschedule"
      new_hearing_attrs = after_disposition_update[:new_hearing_attrs]
      reschedule(
        hearing_day_id: new_hearing_attrs[:hearing_day_id],
        scheduled_time_string: new_hearing_attrs[:scheduled_time_string],
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

  def create_transcription_and_maybe_evidence_submission_window_tasks
    TranscriptionTask.create!(appeal: appeal, parent: self, assigned_to: TranscriptionTeam.singleton)
    unless hearing&.evidence_window_waived
      EvidenceSubmissionWindowTask.create!(appeal: appeal, parent: self, assigned_to: MailTeam.singleton)
    end
  end
end
