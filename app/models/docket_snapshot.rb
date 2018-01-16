class DocketSnapshot < ActiveRecord::Base
  has_many :docket_tracers
  before_validation :set_docket_count, :set_latest_docket_month, on: :create
  after_create :create_tracers

  private

  def set_docket_count
    self.docket_count = Appeal.repository.regular_non_aod_docket_count
  end

  def set_latest_docket_month
    # The latest docket month is updated every Friday
    self.latest_docket_month =
      self.class.where("created_at >= ?", friday).first.try(:latest_docket_month) ||
      Appeal.repository.latest_docket_month
  end

  def create_tracers
    docket_tracers.create(
      Appeal.repository.docket_counts_by_month.map do |row|
        {
          month: Date.new(row["year"], row["month"], 1),
          ahead_count: row["cumsum_n"],
          ahead_and_ready_count: row["cumsum_ready_n"]
        }
      end
    )
  end

  def friday
    today = Date.today
    days_since_friday = (today.wday + 2) % 7
    today - days_since_friday
  end
end
