# frozen_string_literal: true

module AppealAvailableHearingLocations
  extend ActiveSupport::Concern

  def suggested_hearing_location
    # return the closest hearing location
    available_hearing_locations&.min_by do |loc|
      next if !loc.distance.nil?
      
      loc.distance
    end
  end
end
