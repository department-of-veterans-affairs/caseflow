# frozen_string_literal: true

# For a Veteran object, return a summary of all Decision Reviews, Hearings, or anything else
# that has a veteran_file_number on it. Also summarizes available Ratings for the Fakes::BGSService.
# This class is intended for caseflowdemo and local env only.

class VeteranProfile
  KLASSES = [
    Appeal,
    EndProductEstablishment,
    HigherLevelReview,
    Intake,
    RampElection,
    RampRefiling,
    SupplementalClaim
  ].freeze

  def initialize(veteran_file_number:)
    @veteran_file_number = veteran_file_number
  end

  def call
    KLASSES.each do |klass|
      summary[klass.to_s] = klass.where(veteran_file_number: veteran_file_number).count
    end
    summary["Hearing"] = Hearing.joins(:appeal).where(appeals: { veteran_file_number: veteran_file_number }).count
    summary["ratings"] = veteran ? BGSService.new.get_rating_record(veteran.participant_id) : {}
    summary
  end

  private

  attr_reader :veteran_file_number

  def summary
    @summary ||= { file_number: veteran_file_number }
  end

  def veteran
    @veteran ||= VeteranFinder.find_best_match(veteran_file_number)
  end
end
