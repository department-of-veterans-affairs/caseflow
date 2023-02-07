# frozen_string_literal: true

module AppealAvailableHearingLocations
  extend ActiveSupport::Concern

  # :nocov:
  def suggested_hearing_location
    # return the closest hearing location, rejecting locations with nil distances
    available_hearing_locations.map(&:distance)&.reject(&:nil?)&.min_by(&:distance)
  end
  # :nocov:
end
