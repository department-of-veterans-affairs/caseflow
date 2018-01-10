# == Schema Information
#
# Table name: docket_snapshots
#
# id
# created_at
# updated_at
# docket_count
# latest_docket_month

class DocketSnapshot < ActiveRecord::Base
  has_many :docket_tracers
  before_validation :set_docket_count, :set_latest_docket_month, on: :create
  after_create :create_tracers

  private

  def set_docket_count
    docket_count = Appeal.repository.regular_non_aod_docket_count
  end

  def set_latest_docket_month
    # The latest docket month is updated every Friday
    latest_docket_month =
      self.class.where("created_at >= ?", friday).first.try(:latest_docket_month) ||
      Appeal.repository.latest_docket_month
  end

  def create_tracers
    Appeal.repository.docket_counts_by_month.each do |month|
      #
    end
  end

  def friday
    today = Date.today
    days_since_friday = (today.wday + 2) % 7
    today - days_since_friday
  end
end
