# frozen_string_literal: true

class Hearings::WorkflowManager
  attr_reader :hearing_task, :appeal, :hearing
  delegate :reschedule, :reschedule_later, :reschedule_later_with_admin_action, to: :scheduler

  def initialize(hearing_task)
    @hearing_task = hearing_task
    @appeal = hearing_task&.appeal
    @hearing = hearing_task&.hearing
  end

  def hold!
    update_hearing_disposition(disposition: Constants.HEARING_DISPOSITION_TYPES.held)

    create_transcription_and_maybe_evidence_submission_window_tasks
  end

  def postpone!(should_reschedule_later: true)
    update_hearing_disposition(disposition: Constants.HEARING_DISPOSITION_TYPES.postponed)

    create_schedule_hearing_task if should_reschedule_later
  end

  def cancel!
    update_hearing_disposition(disposition: Constants.HEARING_DISPOSITION_TYPES.cancelled)

    create_evidence_submission_task if appeal.is_a? Appeal
  end

  def no_show!
    update_hearing_disposition(disposition: Constants.HEARING_DISPOSITION_TYPES.no_show)

    NoShowHearingTask.create_with_hold(self)
  end

  def withdraw!
    if appeal.is_a?(LegacyAppeal)
      AppealRepository.withdraw_hearing!(appeal)
      AppealRepository.update_location!(appeal, legacy_withdrawal_location)
    else
      create_evidence_submission_task
    end
  end

  def complete!
    if appeal.is_a?(LegacyAppeal)
      update_legacy_appeal_location
    else
      IhpTasksFactory.new(parent).create_ihp_tasks!
    end
  end

  private

  def scheduler
    @scheduler ||= Hearings::Scheduler.new(appeal, hearing_task: hearing_task)
  end

  def create_transcription_and_maybe_evidence_submission_window_tasks
    TranscriptionTask.create!(appeal: appeal, parent: hearing_task, assigned_to: TranscriptionTeam.singleton)
    unless hearing&.evidence_window_waived
      create_evidence_submission_task
    end
  end

  def update_hearing_disposition(disposition:)
    if hearing.is_a?(LegacyHearing)
      hearing.update_caseflow_and_vacols(disposition: disposition)
    else
      hearing.update(disposition: disposition)
    end
  end

  def legacy_withdrawal_location
    if appeal.representatives.empty?
      LegacyAppeal::LOCATION_CODES[:case_storage]
    else
      LegacyAppeal::LOCATION_CODES[:service_organization]
    end
  end

  def create_evidence_submission_task
    EvidenceSubmissionWindowTask.create!(
      appeal: appeal,
      parent: hearing_task.parent,
      assigned_to: MailTeam.singleton
    )
  end

  def create_schedule_hearing_task
    reschedule_later
  end

  def update_legacy_appeal_location
    location = if hearing&.held?
                 LegacyAppeal::LOCATION_CODES[:transcription]
               elsif appeal.representatives.empty?
                 LegacyAppeal::LOCATION_CODES[:case_storage]
               else
                 LegacyAppeal::LOCATION_CODES[:service_organization]
               end

    AppealRepository.update_location!(appeal, location)
  end
end
