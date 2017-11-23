class AppealSeries < ActiveRecord::Base
  has_many :appeals, dependent: :nullify

  delegate :vacols_id,
           :active?,
           :type_code,
           :aod,
           :status,
           to: :latest_appeal

  def latest_appeal
    @latest_appeal ||= fetch_latest_appeal
  end

  def api_sort_date
    appeals.map(&:nod_date).min || DateTime::Infinity.new
  end

  def events
    appeals.flat_map(&:events).uniq.sort_by(&:date)
  end

  private

  def fetch_latest_appeal
    active_appeals.first || appeals_by_decision_date.first
  end

  def active_appeals
    appeals.select(&:active?)
           .sort { |x, y| y.last_location_change_date <=> x.last_location_change_date }
  end

  def appeals_by_decision_date
    appeals.sort { |x, y| y.decision_date <=> x.decision_date }
  end
end
