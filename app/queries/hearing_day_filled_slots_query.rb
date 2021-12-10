# frozen_string_literal: true

##
# Determines the slots count for multple hearings on a day for all hearing days.
#
# This class exists to optimize the process for determining the filled slots
# count for multiple hearings days.
##

class HearingDayFilledSlotsQuery
  attr_reader :hearing_days

  def initialize(hearing_days)
    @hearing_days = hearing_days
  end

  def call
    result = hearing_days.ama_hearings_count_per_day

    hearing_days.legacy_hearings_count_per_day.each do |hearing_day_id, filled_slots_count|
      result[hearing_day_id.to_i] = result.fetch(hearing_day_id.to_i, 0) + filled_slots_count
    end

    result
  end
end
