# frozen_string_literal: true

# Metric ID: 1812216039
# Metric definition: (Total scheduled meetings held - postponed hearings) / total scheduled meetings
# from Caseflow Hearing Schedule

class Metrics::HearingsShowRate < Metrics::Base
  def call
    hearings_by_disposition["held"] / (hearings.count.to_f - hearings_by_disposition["postponed"].to_f)
  end

  def name
    "Hearings Show Rate"
  end

  def id
    "1812216039"
  end

  private

  def hearings
    @hearings ||= begin
      day_ids = HearingDay.where("scheduled_for >= ? and scheduled_for <= ?", start_date, end_date).pluck(:id)
      Hearing.where(hearing_day_id: day_ids)
    end
  end

  def hearings_by_disposition
    @hearings_by_disposition ||= hearings.group(:disposition).count
  end
end
