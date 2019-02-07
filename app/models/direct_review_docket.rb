class DirectReviewDocket < Docket
  DAYS_TO_DECISION_GOAL = 365

  def docket_type
    "direct_review"
  end

  def self.nonpriority_receipts_per_year
    # hardcode this figure as a baseline before we have any data

    today = Time.zone.today

    if today < Time.new(2019, 0o4, 0o1)
      return 38_500
    elsif today < Time.new(2020, 0o4, 0o1)

    end

    # if today < Time.new
  end

  def self.nonpriority_receipts_since; end
end
