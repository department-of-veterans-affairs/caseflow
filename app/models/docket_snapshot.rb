# frozen_string_literal: true

class DocketSnapshot < CaseflowRecord
  has_many :docket_tracers
  before_validation :set_docket_count, :set_latest_docket_month, on: :create
  after_create :create_tracers

  def docket_tracer_for_form9_date(date)
    docket_tracers.find_by_month(date.beginning_of_month)
  end

  def self.latest
    order("created_at").last
  end

  private

  def set_docket_count
    self.docket_count = LegacyAppeal.repository.regular_non_aod_docket_count
  end

  def set_latest_docket_month
    # The latest docket month is updated every Friday
    self.latest_docket_month =
      self.class.find_by("created_at >= ?", friday).try(:latest_docket_month) ||
      LegacyAppeal.repository.latest_docket_month
  end

  def create_tracers
    docket_tracers.create(
      LegacyAppeal.repository.docket_counts_by_month.map do |row|
        {
          month: Date.new(row["year"], row["month"], 1),
          ahead_count: row["cumsum_n"],
          ahead_and_ready_count: row["cumsum_ready_n"]
        }
      end
    )
  end

  def friday
    today = Time.zone.today
    days_since_friday = (today.wday + 2) % 7
    today - days_since_friday
  end
end
