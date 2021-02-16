# frozen_string_literal: true

##
# Shared methods of Hearing and LegacyHearing models
##
module HearingConcern
  extend ActiveSupport::Concern

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

  def veteran_date_of_death_info
    {
     veteran_full_name: appeal.veteran_full_name,
     veteran_appellant_deceased: appeal.veteran_appellant_deceased?,
     veteran_death_date: appeal.veteran_death_date,
     veteran_death_date_reported_at: appeal.veteran_death_date_reported_at,
    }
  end
end
