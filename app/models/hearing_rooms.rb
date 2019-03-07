# frozen_string_literal: true

class HearingRooms
  ROOMS = Constants::HEARING_ROOMS_LIST.freeze

  attr_reader :key

  def initialize(key)
    @key = key
  end

  def label
    location_hash["label"]
  end

  private

  def location_hash
    @location_hash ||= compute_location_hash
  end

  def compute_location_hash
    ROOMS[key] || {}
  end

  class << self
    def find!(key)
      return if key.nil?

      HearingRooms.new(key)
    end
  end
end
