# frozen_string_literal: true

##
# Shared methods of Hearing and LegacyHearing models
##
module HearingConcern
  extend ActiveSupport::Concern

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
end
