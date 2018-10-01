class HearingRooms
  ROOMS = {
    "1" => {
      label: "1 (1W200A)"
    },
    "2" => {
      label: "2 (1W200B)"
    },
    "3" => {
      label: "3 (1W200C)"
    },
    "4" => {
      label: "4 (1W424)"
    },
    "5" => {
      label: "5 (1W428)"
    },
    "6" => {
      label: "6 (1W432)"
    },
    "7" => {
      label: "7 (1W434)"
    },
    "8" => {
      label: "8 (1W435)"
    },
    "9" => {
      label: "9 (1W436)"
    },
    "10" => {
      label: "10 (1W437)"
    },
    "11" => {
      label: "11 (1W438)"
    },
    "12" => {
      label: "12 (1W439)"
    },
    "13" => {
      label: "13 (1W440)"
    }
  }.freeze

  attr_reader :key

  def initialize(key)
    @key = key
  end

  def label
    location_hash[:label]
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
