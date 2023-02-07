# frozen_string_literal: true

module AppealAvailableHearingLocations
  extend ActiveSupport::Concern

  # :nocov:
  def suggested_hearing_location
    # return the closest hearing location, rejecting locations with nil distances
    # available_hearing_locations&.reject { |loc| loc.distance.nil? }&.min_by { |loc| loc.distance }
    # distance_is_nil = proc { |loc| loc.distance.nil? }

    available_hearing_locations&.reject&.min_by(&:distance)
  end
  # :nocov:
end
