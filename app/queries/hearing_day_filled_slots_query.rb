# frozen_string_literal: true

##
# Determines the slots count for multple hearings on a day for all hearing days.
#
# This class exists to optimize the process for determining the filled slots
# count for multiple hearings days.
##

class HearingDayFilledSlotsQuery
  def initialize(hearing_days)
    @hearing_days = hearing_days
  end

  def call
    result = ama_hearings_count_per_day
    legacy_hearings_count_per_day.each do |hearing_day_id, filled_slots_count|
      result[hearing_day_id] = 0 if result[hearing_day_id].blank?

      result[hearing_day_id] += filled_slots_count
    end

    result
  end

  def ama_hearings_count_per_day
    Hearing.where(hearing_day: @hearing_days).where(
      "disposition NOT in (?) or disposition is null",
      Hearing::CLOSED_HEARING_DISPOSITIONS
    ).group(:hearing_day_id).count
  end

  def legacy_hearings_count_per_day
    vacols_ids = LegacyHearing.where(hearing_day_id: @hearing_days.pluck(:id)).pluck(:hearing_day_id, :vacols_id)
    legacy_dispositions = vacols_ids.map do |_h_day_id, vacols_id|
      [
        vacols_id, Rails.cache.read(LegacyHearing.cache_key_for_field(:disposition, vacols_id))
      ]
    end.to_h

    filtered_hearings = vacols_ids.select do |_h_day_id, vacols_id|
      disposition = legacy_dispositions[vacols_id]
      Hearing::CLOSED_HEARING_DISPOSITIONS.exclude?(disposition)
    end

    filtered_hearings
      .group_by(&:shift)
      .transform_values(&:count)
  end
end
