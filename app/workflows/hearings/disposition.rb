# frozen_string_literal: true

class Hearings::Disposition
  attr_reader :hearing_task, :appeal, :hearing
  delegate :reschedule, :reschedule_later, :reschedule_later_with_admin_action, to: :scheduler

  def initialize(hearing_task, scheduler: nil)
    @hearing_task = hearing_task
    @appeal = hearing_task&.appeal
    @hearing = hearing_task&.hearing
    @scheduler = scheduler || Hearings::Scheduler.new(appeal, hearing_task: hearing_task)
  end

  def hold!
    update_disposition(Constants.HEARING_DISPOSITION_TYPES.held)

    create_transcription_and_maybe_evidence_submission_window_tasks
  end

  def postpone_and_reschedule!(hearing_params)
    postpone!

    reschedule(hearing_params)
  end

  def postpone_and_reschedule_later!(admin_action_attributes: nil)
    postpone!

    if admin_action_attributes.nil?
      reschedule_later
    else
      reschedule_later_with_admin_action(admin_action_attributes)
    end
  end

  def cancel!
    update_disposition(Constants.HEARING_DISPOSITION_TYPES.cancelled)

    create_evidence_submission_task if appeal.is_a? Appeal
  end

  def no_show!
    update_disposition(Constants.HEARING_DISPOSITION_TYPES.no_show)

    NoShowHearingTask.create_with_hold(hearing_task.disposition_task)
  end

  def admin_changes_needed_after_hearing_date(instructions: nil)
    create_change_hearing_disposition_task(instructions)
  end

  private

  def postpone!
    update_disposition(Constants.HEARING_DISPOSITION_TYPES.postponed)
  end

  def update_disposition(disposition)
    if hearing.is_a?(LegacyHearing)
      hearing.update_caseflow_and_vacols(disposition: disposition)
    else
      hearing.update(disposition: disposition)
    end
  end

  def create_evidence_submission_task
    EvidenceSubmissionWindowTask.create!(
      appeal: appeal,
      parent: hearing_task.parent,
      assigned_to: MailTeam.singleton
    )
  end

  def create_transcription_and_maybe_evidence_submission_window_tasks
    TranscriptionTask.create!(appeal: appeal, parent: hearing_task, assigned_to: TranscriptionTeam.singleton)
    unless hearing&.evidence_window_waived
      create_evidence_submission_task
    end
  end

  def create_change_hearing_disposition_task(instructions = nil)
    task_names = [AssignHearingDispositionTask.name, ChangeHearingDispositionTask.name]
    active_disposition_tasks = hearing_task.children.open.where(type: task_names).to_a

    ChangeHearingDispositionTask.create!(
      appeal: appeal,
      parent: self,
      instructions: instructions.present? ? [instructions] : nil
    )
    active_disposition_tasks.each { |task| task.update!(status: Constants.TASK_STATUSES.completed) }
  end

  def legacy_withdrawal_location
    if appeal.representatives.empty?
      LegacyAppeal::LOCATION_CODES[:case_storage]
    else
      LegacyAppeal::LOCATION_CODES[:service_organization]
    end
  end
end
