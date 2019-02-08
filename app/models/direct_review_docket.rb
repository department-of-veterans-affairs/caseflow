class DirectReviewDocket < Docket
  DAYS_TO_DECISION_GOAL = 365

  def docket_type
    "direct_review"
  end

  def self.nonpriority_receipts_per_year
    today = Time.zone.today

    if today < Date.new(2019, 4, 1)
      # Hardcode this figure as a baseline since we won't have enough data to judge.
      return 38_500
    elsif today < Date.new(2020, 2, 29)
      # If it's been fewer than 365 days since March 1st, return a weighted number of appeals.
      march_first = Date.new(2019, 3, 1)
      days_since_march_first = Integer(today - march_first)
      appeals_since_march_first =
        DirectReviewDocket.all_nonpriority.where("receipt_date => ?", march_first).count
      # appeals_since_march_first / adjusted_appeals = days_since_march_first / 365
      (appeals_since_march_first * 365) / days_since_march_first
    else
      DirectReviewDocket.all_nonpriority.where("receipt_date => ?", 1.year.ago).count
    end
  end

  def self.all_nonpriority
    Appeal.all_nonpriority.where(docket_type: "direct_review")
  end
end
