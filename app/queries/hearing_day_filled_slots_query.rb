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
      result[hearing_day_id.to_i] = result.fetch(hearing_day_id.to_i, 0) + filled_slots_count
    end

    result
  end

  private

  def ama_hearings_count_per_day
    Hearing.where(hearing_day: @hearing_days).where(
      "disposition NOT in (?) or disposition is null",
      Hearing::CLOSED_HEARING_DISPOSITIONS
    ).group(:hearing_day_id).count
  end

  def legacy_hearings_count_per_day
    vacols_ids = LegacyHearing.where(hearing_day_id: @hearing_days.pluck(:id)).pluck(:vacols_id)

    vacols_ids.in_groups_of(1000, false).reduce({}) do |acc, vacols_batched_ids|
      acc.merge(
        VACOLS::CaseHearing.where(hearing_pkseq: vacols_batched_ids)
         .where("hearing_disp NOT in (?) or hearing_disp is null", VACOLS::CaseHearing::CLOSED_HEARING_DISPOSITIONS)
         .group(:vdkey)
         .count
      )
    end
  end
end
