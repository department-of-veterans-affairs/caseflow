# frozen_string_literal: true

module HearingLocationConcern
  extend ActiveSupport::Concern

  def hearing_location_or_regional_office
    location.nil? ? regional_office : location
  end
end