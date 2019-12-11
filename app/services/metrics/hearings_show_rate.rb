# frozen_string_literal: true

# Metric ID: 1812216039
# Metric definition: (Total scheduled meetings held - postponed hearings) / total scheduled meetings
# from Caseflow Hearing Schedule

class Metrics::HearingsShowRate < Metrics::Base
  def call
    (hearings_by_disposition["held"] - hearings_by_disposition["postponed"]) / hearings.count
  end

  def name
    "Hearings Show Rate"
  end

  def id
    "1812216039"
  end

  private

  def hearings
    @hearings ||= Hearing.where("scheduled_for > ? AND scheduled_for <", start_date, end_date)
  end

  def hearings_by_disposition
    @hearings_by_disposition ||= hearings.group(:disposition).count
  end
end
