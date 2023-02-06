# frozen_string_literal: true

module AppealAvailableHearingLocations
  extend ActiveSupport::Concern

  # :nocov:
  def suggested_hearing_location
    # return the closest hearing location, rejecting locations with nil distances
    distance = proc(&:distance)
    available_hearing_locations&.reject distance.nil? &.min_by(distance)
  end
  # :nocov:
end
