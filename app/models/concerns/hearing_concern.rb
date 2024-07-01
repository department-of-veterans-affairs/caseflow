# frozen_string_literal: true

##
# Shared methods of Hearing and LegacyHearing models
##
module HearingConcern
  extend ActiveSupport::Concern
  include RunAsyncable

  CLOSED_HEARING_DISPOSITIONS = [
    Constants.HEARING_DISPOSITION_TYPES.postponed,
    Constants.HEARING_DISPOSITION_TYPES.cancelled,
    Constants.HEARING_DISPOSITION_TYPES.scheduled_in_error
  ].freeze

  # NOTE: for LegacyHearing, this makes a call to VACOLS
  def postponed?
    disposition == Constants.HEARING_DISPOSITION_TYPES.postponed
  end

  # NOTE: for LegacyHearing, this makes a call to VACOLS
  def cancelled?
    disposition == Constants.HEARING_DISPOSITION_TYPES.cancelled
  end

  # NOTE: for LegacyHearing, this makes a call to VACOLS
  def no_show?
    disposition == Constants.HEARING_DISPOSITION_TYPES.no_show
  end

  # NOTE: for LegacyHearing, this makes a call to VACOLS
  def held?
    disposition == Constants.HEARING_DISPOSITION_TYPES.held
  end

  # NOTE: for LegacyHearing, this makes a call to VACOLS
  def scheduled_in_error?
    disposition == Constants.HEARING_DISPOSITION_TYPES.scheduled_in_error
  end

  def postponed_or_cancelled_or_scheduled_in_error?
    postponed? || cancelled? || scheduled_in_error?
  end

  def rescue_and_check_toggle_veteran_date_of_death_info
    if FeatureToggle.enabled?(:view_fnod_badge_in_hearings, user: RequestStore.store[:current_user])
      # Also found in hearing_serializer.rb
      # The BGS part of this rescue block is originally from task_column_serializer.rb,
      # added to solve the problem detailed here:
      # https://github.com/department-of-veterans-affairs/caseflow/pull/15804
      begin
        veteran_date_of_death_info
      rescue BGS::PowerOfAttorneyFolderDenied, StandardError => error
        Raven.capture_exception(error)
        nil
      end
    end
  end

  def veteran_date_of_death_info
    {
      veteran_full_name: appeal.veteran_full_name,
      veteran_appellant_deceased: appeal.veteran_appellant_deceased?,
      veteran_death_date: appeal.veteran_death_date,
      veteran_death_date_reported_at: appeal.veteran_death_date_reported_at
    }
  end

  def open_hearing_disposition_task_id
    hearing_task = appeal.tasks.open.where(type: HearingTask.name).find { |task| task.hearing&.id == id }
    hearing_task
      &.children
      &.open
      &.find_by(type: [AssignHearingDispositionTask.name, ChangeHearingDispositionTask.name])
      &.id
  end

  def poa_name
    poa = BgsPowerOfAttorney.find_by(file_number: appeal&.veteran_file_number)

    if poa.blank? && is_a?(Hearing)
      poa = BgsPowerOfAttorney.find_by(claimant_participant_id: appeal.claimant&.participant_id)
    end

    poa&.representative_name
  end

  def calculate_submission_window
    # End of evidence submission window is 90 days after scheduled_for, unless
    # that falls on a weekend or holiday.
    # Note: It would be ideal to retrieve an EvidenceSubmissionWindowTask for this
    # hearing, and use its `timer_ends_at` date, rather than calculating this window here.
    # However, since EvidenceSubmissionWindowTasks are currently created for AMA appeals,
    # but not Legacy ones, we'll use this method for now.
    end_date = scheduled_for.to_date + 90.days
    weekend, holiday = weekend_and_holiday(end_date)

    # Make sure the end date is not a weekend or holiday
    while weekend || holiday
      end_date += 1.day
      weekend, holiday = weekend_and_holiday(end_date)
    end

    end_date
  end

  def subject_for_conference
    "#{docket_number}_#{id}_#{self.class}"
  end

  def nbf
    scheduled_for.beginning_of_day.to_i
  end

  def exp
    scheduled_for.end_of_day.to_i
  end

  # Returns the new 1:1 conference link object for legacy and ama hearings
  # that are non virtual and have a webex meeting type
  def non_virtual_conference_link
    ConferenceLink.find_by(hearing: self)
  end

  # Associate hearing with transcription files across multiple dockets and order accordingly
  def transcription_files_by_docket_number
    # Remove hyphen in case of counter at end of file name to allow for alphabetical sort
    transcription_files.sort_by { |file| file.file_name.split("-").join }.group_by(&:docket_number).values
  end

  # Group transcription files by docket number before mapping through nested array and serializing
  def serialized_transcription_files
    transcription_files_by_docket_number.map do |file_groups|
      file_groups.map do |file|
        TranscriptionFileSerializer.new(file).serializable_hash[:data][:attributes]
      end
    end
  end

  def start_non_virtual_hearing_job?
    disposition.nil? && conference_provider == "webex" &&
      virtual_hearing.nil? && ConferenceLink.find_by(hearing: self).nil?
  end

  def start_non_virtual_hearing_job
    perform_later_or_now(Hearings::CreateNonVirtualConferenceJob, hearing: self)
  end

  # Complexity of create schedule hearing task was too large - had to break out
  def maybe_create_non_virtual_conference
    start_non_virtual_hearing_job if start_non_virtual_hearing_job?
  end
end
